classdef (Hidden, Sealed) RunnerSolvers < lin.runner.AbstractRunnerProblem
    %RunnerSolvers Compare several linear solvers for Ax=b.
    %   This class runs LAMG cycles on a problem and computes the
    %   asymptotic convergence rate. It can also compare LAMG with other
    %   solvers.
    %
    %   See also: RUNNER, ITERATIVEMETHOD.
    
    %=========================== PROPERTIES ==============================
    properties (Constant, GetAccess = private)
        logger          = core.logging.Logger.getInstance('lin.runner.RunnerSolvers')
    end
    
    properties (GetAccess = private, SetAccess = private)
        % Dependencies
        runOptions                      % Run options
        % Fields
        solvers                         % Map of solver-name-to-runner
        solverContext                   % An application context shared by all solvers
    end
    
    %======================== CONSTRUCTORS ============================
    methods
        function obj = RunnerSolvers(problemFactory, runOptions)
            % Constructor.
            obj = obj@lin.runner.AbstractRunnerProblem(problemFactory);
            obj.solvers = containers.Map();
            obj.runOptions = runOptions;
            obj.solverContext = lin.runner.SolverContext;
        end
    end
    
    %======================== METHODS ====================================
    methods
        function addSolver(obj, name, solver)
            % Add an algorithm runner to the list of solvers. contextKey =
            % solver identifier in solver context.
            runner = lin.runner.RunnerSolver(obj.problemFactory, name, solver, obj.runOptions);
            runner.solverContext = obj.solverContext;
            obj.solvers(name) = runner;
        end
    end
    
    %======================== IMPL: AbstractRunnerProblem ================
    methods
        function fieldNames = fieldNames(obj)
            % Return a cell array of method labels. The elements of the
            % data array returned from run() correspond to these labels.
            
            % Compute # fields
            staticFields = {'numNodes', 'numEdges', 'tMvm'};
            numStaticFields = numel(staticFields);
            numFields = numStaticFields + ...
                sum(cellfun(@(x)(numel(x.fieldNames)), values(obj.solvers)));
            fieldNames = cell(numFields, 1);
            
            % Build field list
            count = 1;
            fieldNames(1:numStaticFields) = staticFields;
            count = count + numStaticFields;
            for k = keys(obj.solvers)
                key = k{:};
                f = obj.solvers(key).fieldNames;
                sz = numel(f);
                fieldNames(count:count+sz-1) = ...
                    cellfun(@(x)(strcat(key, upper(x(1)), x(2:end))), f, 'UniformOutput', false);
                count = count + sz;
            end
        end
    end
    
    methods (Access = protected)
        function [result, details] = runOnProblem(obj, problem)
            % Compare all solvers on a GRAPH instance and return a
            % numerical array RESULT of solver performance statistics.
            
            % Measure matrix-vector-multiplication (MVM) time
            tMvm = mvmTime(problem.A, 5);
            
            % Save solver-independent statistics
            result = [
                problem.g.numNodes ...
                problem.g.numEdges ...
                tMvm ...
                ];
            details = cell(1, numel(obj.solvers.keys()));
            count = 0;
            obj.solverContext.clear();
            
            % Run all solvers
            for k = obj.solvers.keys()
                key     = k{:};
                count   = count+1;
                runner  = obj.solvers(key);
                [r, d] = runner.runOnProblem(problem);
                
                % Clear all setup objects except LAMG objects, since we
                % typically only re-run our solver with multiple options
                % for a single problem, if at all
                if (obj.runOptions.clearWhenDone)
                    obj.solverContext.clearLargeObjects({'lamg'});
                end

                % Debugging printouts
                if (obj.logger.infoEnabled)
                    tTotal = runner.totalTime(d.tSetup, d.tSolve);
                    obj.logger.info('%-10s | total %.1e sec | setup %.1e sec | solve %.1e sec', ...
                        key, tTotal, d.tSetup, d.tSolve);
                    if (isfield(d, 'acf'))
                        obj.logger.info(' | acf %.3f', d.acf);
                    end
                    if (isfield(d, 'numLevels'))
                        obj.logger.info(' | lev %d', d.numLevels);
                    end
                    obj.logger.info('\n');
                end
                result = [result r]; %#ok
                details{count} = d;
            end
            
            %             %--------------------------------------------------------
            %             % Run the CMG algorithm for comparison
            %             %--------------------------------------------------------
            %             if (obj.cmg)
            %                 try
            %                     if (obj.logger.debugEnabled)
            %                         obj.logger.debug('\n--- running CMG
            %                         Setup ---\n');
            %                     end tstart   = tic; pfun     =
            %                     cmg_sdd(g.laplacian, struct('display',
            %                     false)); cmgSetup = toc(tstart); cmgSetup
            %                     = cmgSetup / g.numEdges;
            %
            %                     if (obj.logger.debugEnabled)
            %                         obj.logger.debug('\n--- running CMG
            %                         Solve ---\n');
            %                     end tstart   = tic; % TODO: make
            %                     tolerance relative for fair comparison
            %                     [dummy1, flag, dummy2, dummy3, resHistory] =
            %                     pcg(g.laplacian, problem.b,
            %                     obj.mlOptions.errorReductionTol, 10000,
            %                     pfun); cmgSolve = toc(tstart); cmgSolve =
            %                     obj.normalizedSolveTime(cmgSolve,
            %                     problem.g.numEdges, resHistory); if (flag
            %                     ~= 0)      % Convergence failure
            %                         cmgSolve = Inf;
            %                     end
            %                 catch e %#ok
            %                     % CMG solver failed
            %                 end
            %             end
            %
            
            %--------------------------------------------------------
            % Clean up, report results
            %--------------------------------------------------------
            % Free memory
            if (obj.runOptions.clearWhenDone)
                obj.solverContext.clearLargeObjects();
                d.setup = [];
                clear problem;
            end
%            [dummy, sv] = memory;
%            if (obj.logger.infoEnabled)
%                obj.logger.info('Available mem %.2f GB\n', sv.PhysicalMemory.Available/10^9);
%                obj.logger.info('=======================================================================================\n');
%            end
        end
    end
    
    %======================== PRIVATE METHODS =========================
    methods (Access = private)
    end
end
