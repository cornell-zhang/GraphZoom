classdef (Sealed) SolverLamg < lin.api.Solver & amg.api.HasOptions
    %LAMG Lean Algebraic Multigrid SDD linear solver.
    %   This class is a decorator of SolverLamgLaplacian that can solve any
    %   symmetric diagonally-dominant system by augmenting it to a larger
    %   Laplacian system.
    %
    %   See also: SOLVERS, OPTIONS, GRAPH, CYCLES, PROBLEM,
    %   MULTILEVELSETUP.
    
    %======================== PROPERTIES ==============================
    properties (GetAccess = private, SetAccess = private)
        solverLaplacian     % LAMG graph Laplacian solver delegate
    end
    
    %======================== CONSTRUCTORS ============================
    methods
        function obj = SolverLamg(options, varargin)
            % Create LAMG SDD solver from input options.
            options = amg.api.Options.fromStruct(options, varargin{:});
            obj = obj@amg.api.HasOptions(options);
            obj = obj@lin.api.Solver('lamg', true);
            obj.solverLaplacian = amg.solve.SolverLamgLaplacian(options, varargin{:});
        end
    end
    
    %======================== IMPL: Solver ============================
    methods (Access = protected)
        function setup = doSetup(obj, problem)
            % Create an augmented system and delegate to the Laplacian
            % solver to create a setup hierarchy. Assuming g.laplacian
            % stores the SDD system.
            if (~isempty(problem.g))
                % Graph object set ==> a Laplacian problem.
                setup = obj.solverLaplacian.setup('problem', problem);
            else
                % Graph object not set ==> an SDD problem. Augment to a Laplacian.
                % Decompose A into its parts
                A   = problem.A;
                dt  = sum(A);
                d   = dt';
                n   = size(A,1);
                L   = [[A sparse(n,n) -d]; [sparse(n,n) A -d]; [-dt -dt 2*sum(d)]];
                coord = problem.coord;
                if (~isempty(coord))
                    % Corresponding to the variables [x; -x; xi]
                    coord = [coord; coord; mean(coord)];
                end
                g   = graph.api.Graph.newNamedInstance('graph', 'laplacian', L, coord);
                p   = lin.api.Problem(L, [], g, coord);
                setupLaplacian = obj.solverLaplacian.setup('problem', p);
                setup = struct('problem', problem, 'setupLaplacian', setupLaplacian);
            end
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
            if (~isfield(setup, 'setupLaplacian'))
                % Laplacian problem
                [x, success, errorNormHistory, details] = ...
                    obj.solverLaplacian.solve(setup, b, varargin{:});
            else
                % SDD problem
                [y, success, errorNormHistory, details] = ...
                    obj.solverLaplacian.solve(setup.setupLaplacian, [b; -b; 0], varargin{:});
                % Restore original variables
                x = y(1:size(b,1));
            end
        end
    end
    
    %======================== METHODS =================================
end
