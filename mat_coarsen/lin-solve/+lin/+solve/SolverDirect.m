classdef (Sealed) SolverDirect < lin.api.Solver
    %LAMG Direct linear solver (MATLAB backslash / UMFPack).
    %   This class adapts the blackslash operator to the Solver interface.
    %
    %   See also: SOLVER, SOLVERS.
    

    %======================== CONSTRUCTORS ============================
    methods
        function obj = SolverDirect(dummy, varargin) %#ok
            % Create a direct solver. It has no context key.
            obj = obj@lin.api.Solver([], false);
        end
    end

    %======================== IMPL: Solver ============================
    methods (Access = protected)
        function setup = doSetup(obj, problem) %#ok<MANU>
            % Set up augmented system.
            u = ones(size(problem.A, 1), 1);
            A = [[problem.A u]; [u' 0]];
            setup = struct('A', A);
        end
    end
    
    methods
        function fieldNames = detailsFieldNames(obj) %#ok
            % Return a cell array of solver public output fields returned
            % in the DETAILS argument of SOLVE. These may be all or a
            % subset of DETAILS' field list.
            fieldNames = {};
        end
        
        function [x, success, errorNormHistory, details] = solve(obj, setup, b, varargin) %#ok
            % Perform linear solve on A*x=B.
            
            % Set solve options, in particular the # recombined iterates at
            % finest level
            x = setup.A \ [b; 0];
            x = x(1:end-1);
            success = true;
            errorNormHistory = [];
            details = struct('errorNormHistory', errorNormHistory);
        end
    end
end
