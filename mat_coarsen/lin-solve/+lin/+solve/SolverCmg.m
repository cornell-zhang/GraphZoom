classdef (Sealed) SolverCmg < lin.api.Solver & amg.api.HasOptions
    %LAMG Combinatorical Multigrid (CMG) linar solver.
    %   This class adapts the CMG MATLAB code (I. Koutis) to the Solver interface.
    %
    %   See also: SOLVER, SOLVERS.
    
   %=========================== PROPERTIES ==============================
    properties (Constant, GetAccess = private)
        logger = core.logging.Logger.getInstance('lin.solve.SolverCmg')
    end
    
    %======================== CONSTRUCTORS ============================
    methods
        function obj = SolverCmg(options, varargin)
            % Create a CMG solver.
            obj = obj@lin.api.Solver('cmg', true);
            options = amg.api.Options.fromStruct(options, varargin{:});
            obj = obj@amg.api.HasOptions(options);
        end
    end

    %======================== IMPL: Solver ============================
    methods (Access = protected)
        function setup = doSetup(obj, problem) %#ok<MANU>
            % Create CMG sparsifier (setup phase).
            
            % Smaller coarsest level seems to be safer for more robust PCG
            % convergence, albeit at the expense of additional work.
            pfun    = cmg_sdd(problem.A, struct('display', false, 'direct', 100));
            
            % Recommended by Ioannis Koutis on 9-JAN-12 to improve
            % PCB's numerical stability
            meanb   = @(b) b - mean(b);
            qfun    = @(b) meanb(pfun(meanb(b)));

            setup   = struct('pfun', qfun, 'A', problem.A);
        end
    end
    
    methods
        function fieldNames = detailsFieldNames(obj) %#ok
            % Return a cell array of solver public output fields returned
            % in the DETAILS argument of SOLVE. These may be all or a
            % subset of DETAILS' field list.
            fieldNames = {};
        end
        
        function [x, success, errorNormHistory, details] = solve(obj, setup, b, varargin)
            % Perform linear solve on A*x=B.
            
            % Make tolerance relative for fair comparison of the true ACF
            % of this method with LAMG's ACF
            A = setup.A;
            tol = min(1, norm(b-A*rand(size(A,1),1))*obj.options.errorReductionTol);
            [x, flag, dummy1, dummy2, errorNormHistory] = pcg(A, b, tol, 10000, setup.pfun); %#ok
            clear dummy1 dummy2;
            success = (flag == 0);
            details = struct('flag', flag, 'errorNormHistory', errorNormHistory);
            if (obj.logger.debugEnabled)
                obj.logger.debug('Residual history:\n');
                disp(errorNormHistory);
            end
        end
    end
end
