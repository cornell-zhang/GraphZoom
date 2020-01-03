classdef (Sealed) SolverLamgLaplacian < lin.api.Solver & amg.api.HasOptions
    %LAMG Lean Algebraic Multigrid graph Laplacian linear solver.
    %   This class provides a simple interface to run the LAMG linear
    %   solver on a linear problem A*X=B, where A is a symmetric NxN graph
    %   adjacency matrix and B is an NxM matrix (usually M=1, but could be
    %   arbitrary). A is typically the symmetric adjacency matrix of an
    %   graph.api.Graph object, but could be any symmetric sparse matrix.
    %
    %   Separate methods are available for the setup and solve phases so
    %   that the multi-level hierarchy (which depends only on the
    %   left-hand-side matrix A) can be reused for multiple right-hand-side
    %   vectors B.
    %
    %   LAMG options are specified by the class amg.api.Options. The
    %   default options should work for any graph, although you can
    %   customize various aspects of the LAMG algorithm (cf. documentation
    %   in the Options class for more details).
    %
    %   Usage example (see lamg_example.m): % Construct a solver lamg =
    %   Solvers.newSolver('lamg'); % Create a graph adjacency matrix A.
    %   Note: g.laplacian is the % corresponding Laplacian matrix. g =
    %   Graphs.grid('fd', [20 20]); A = g.adjacency; % Setup phase:
    %   construct a LAMG multi-level hierarchy setup = lamg.setup(A);  % Or
    %   setup = lamg.setup(g); % Solve phase: set up a compatible RHS b
    %   (remember: A is singular) % and solve A*x=b b = (1:size(A,1))'; b =
    %   b - mean(b); [x, details] = lamg.linearSolve(setup, b);
    %
    %    x =
    %
    %       -17.4562 -17.4325 -17.3875 -17.3237 ...
    %
    %    details =
    %
    %           stats: [1x1 struct]
    %     convHistory: [20x1 double]
    %           index: 0.3961
    %
    %
    %   See also: SOLVERS, OPTIONS, GRAPH, CYCLES, PROBLEM,
    %   MULTILEVELSETUP.
    
    %======================== PROPERTIES ==============================
    properties (GetAccess = private, SetAccess = private)
        setupBuilder    % Multi-level setup builder
    end
    
    %======================== CONSTRUCTORS ============================
    methods
        function obj = SolverLamgLaplacian(options, varargin)
            % Create LAMG solver from input options.
            options = amg.api.Options.fromStruct(options, varargin{:});
            obj = obj@amg.api.HasOptions(options);
            obj = obj@lin.api.Solver('lamg', true);
            obj.setupBuilder = amg.setup.MultilevelSetup(options);
        end
    end
    
    %======================== IMPL: Solver ============================
    methods (Access = protected)
        function setup = doSetup(obj, problem)
            % Perform solver setup phase. Depends on input matrix A (<==>
            % input graph G) only.
            setup = obj.setupBuilder.build(problem);
        end
    end
    
    methods
        function fieldNames = detailsFieldNames(obj) %#ok
            % Return a cell array of solver public output fields returned
            % in the DETAILS argument of SOLVE. These may be all or a
            % subset of DETAILS' field list.
            fieldNames = {'numLevels', 'acf'};
        end
        
        function [x, success, errorNormHistory, details] = solve(obj, setup, b, varargin)
            % Perform linear solve on A*x=B using the setup object SETUP
            % construcated for A. VARARGIN contains custom solve options.
            % Return the approximate solution X and statistics in the
            % struct DETAILS. SUCCESS = boolean success code.
            % ERRORNORMHISTORY = optional error norm history (for iterative
            % solvers only). VARARGIN contains solve arguments that
            % potentially override the default solver options.
            
            % Run the LAMG linear solver
            problem             = lin.api.Problem(setup.level{1}.A, b, setup.level{1}.g);
            [x, details]        = obj.linearSolve(setup, problem, varargin{:});
            
            % Save stats
            success             = (details.acf < 1); % && details.success;
            errorNormHistory    = details.stats.errorNormHistory;
            details.numLevels   = setup.numLevels;
            details.work        = setup.cycleComplexity;
        end
    end
    
    %======================== METHODS =================================
    methods (Static)
        function cycle = solveCycle(setup, b, opts, varargin)
            % Return a numLevels-level LAMG solution cycle for the linear
            % problem Ax=b at level FINEST, using the LAMG setup hierarchy
            % SETUP. VARARGIN contains additional cycle input arguments
            % (cycleIndex, finest, numLevels).
            
            % Read and set input options & arguments
            args        = amg.solve.SolverLamgLaplacian.parseArgs(varargin{:});
            if (isempty(args.cycleIndex))
                args.cycleIndex = setup.cycleIndex;
            end
            % Can't have more levels in cycles than setup
            numLevels   = min(opts.cycleNumLevels, setup.numLevels-args.finest+1);
            processor   = amg.solve.ProcessorSolve(setup, args.finest, numLevels, b, opts);
            cycle       = amg.level.Cycle(processor, args.cycleIndex, numLevels, args.finest);
        end
    end
    
    methods (Access = private)
        function [x, details] = linearSolve(obj, setup, problem, varargin)
            % Run a single solve phase of the linear problem A*x=b. Return
            % solve time and run statistics.
            opts = amg.api.Options.fromStruct(obj.options, varargin{:});
            acfComputer  = lin.api.AcfComputer(...
                'initialGuessNorm', opts.initialGuessNorm, ...
                'maxIterations', opts.numCycles, ...
                'errorNorm', opts.errorNorm, ...
                'errorReductionTol', opts.errorReductionTol, ...
                'logLevel', opts.logLevel, ...
                'removeZeroModes', 'none', ...
                'sampleSize', 3, ...
                'acfEstimate', 'smooth-filter', ...
                varargin{:});
            
            if ((setup.numLevels >= 2) && setup.level{2}.isExactElimination)
                % Finest = elimination level. Solve problem at level 2,
                % interpolate the solution only at the very end.
                coarseLev = setup.level{2};
                % Include restriction in solve time
                [b, bStage] = coarseLev.restrict(problem.b);
                
                % Solve the level-2 problem
                if (coarseLev.g.numNodes == 1)
                    % Border case: one-node graph
                    acf = 0;
                    details = struct();
                    details.stats.errorNormHistory = 0;
                    x = 0;
                else
                    if (obj.options.pcg)
                        % Feed LAMG as a preconditioner to CG
                        problem2 = lin.api.Problem(coarseLev.A, b, coarseLev.g);
                        precond = @(b)(amg.solve.SolverLamgLaplacian.preconditionerLevel2(setup, opts, b));
                        [x, flag, dummy1, dummy2, e] = pcg(problem2.A, problem2.b, ...
                            min(1,1e-3*obj.options.errorReductionTol*norm(problem2.A,1)), 10000, precond); %#ok
                        details = struct('flag', flag, 'errorNormHistory', e, ...
                            'success', flag == 0);
                        details.stats.errorNormHistory = e;
                        if (numel(e) <= 1)
                            acf = 0;
                        else
                            acf = (e(end)/(e(1)+eps))^(1/(numel(e)-1));
                        end
                        
                    else
                        cycle = amg.solve.SolverLamgLaplacian.solveCycle(setup, b, opts, 'finest', 2);
                        problem2 = lin.api.Problem(coarseLev.A, b, coarseLev.g);
                        if (~isempty(opts.x0))
                            x0 = coarseLev.coarseType(opts.x0);
                            [acf, details, x] = acfComputer.run(problem2, cycle, x0);
                        else
                            [acf, details, x] = acfComputer.run(problem2, cycle);
                        end
                    end
                end
                % Include restriction in solve time
                x = coarseLev.interpolate(x, bStage);
            else
                % Cycling at the finest level
                if (obj.options.pcg)
                    % Feed LAMG as a preconditioner to CG
                    precond = @(b)(amg.solve.SolverLamgLaplacian.preconditioner(setup, opts, b));
                    A = setup.level{1}.A;
                    [x, flag, dummy1, dummy2, e] = pcg(A, problem.b, ...
                        min(1,1e-3*obj.options.errorReductionTol*norm(A,1)), 10000, precond); %#ok
                    details = struct('flag', flag, 'errorNormHistory', e, ...
                        'success', flag == 0);
                    details.stats.errorNormHistory = e;
                    if (numel(e) <= 1)
                        acf = 0;
                    else
                        acf = (e(end)/(e(1)+eps))^(1/(numel(e)-1));
                    end
                else
                    % LAMG as a stand-alone solver
                    cycle               = amg.solve.SolverLamgLaplacian.solveCycle(setup, problem.b, opts);
                    [acf, details, x]   = acfComputer.run(problem, cycle);
                    details.success     = 1;
                end
            end
            % Set return fields
            details.acf = acf;
            details.weakEdgePortion = setup.level{1}.weakEdgePortion;
            details.errorNormHistory = details.stats.errorNormHistory; % For API compatibility
        end
    end
    
    %======================== METHODS =================================
    methods (Static, Access = private)
        function args = parseArgs(varargin)
            % Parse cycle input arguments.
            p                   = inputParser;
            p.FunctionName      = 'testCycleAtLevel';
            p.KeepUnmatched     = true;
            p.StructExpand      = true;
            
            p.addParamValue('cycleIndex', [], @isnumeric); % cycle index at all levels
            p.addParamValue('finest', 1, @isPositiveIntegral); % Finest level index
            
            p.parse(varargin{:});
            args = p.Results;
        end
        
        function x = preconditioner(setup, opts, b)
            % LAMG CG preconditioner at level 1. Approximately computes
            % A\b.
            cycle = amg.solve.SolverLamgLaplacian.solveCycle(setup, b, opts);
            x0 = zeros(size(b,1), size(b,2));
            x = cycle.run(x0);
        end
        
        function x = preconditionerLevel2(setup, opts, b)
            % LAMG CG preconditioner at level 2. Approximately computes
            % A\b.
            cycle = amg.solve.SolverLamgLaplacian.solveCycle(setup, b, opts, 'finest', 2);
            x0 = zeros(size(b,1), size(b,2));
            x = cycle.run(x0);
        end
    end
end
