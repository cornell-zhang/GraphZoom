classdef (Hidden) RelaxGaussSeidelOptimized < amg.relax.Relax
    %RELAX Gauss-Seidel relaxation scheme (optimized).
    %   This is an interface for all damped relaxation methods of the type
    %
    %       M*X + N*XOLD = B XNEW = (1-w)*XOLD + w*X
    %
    %   to solve the level LEVEL problem A*X=B, where A=M+N is the method's
    %   splitting and omega is the damping parameter.
    
    %======================== MEMBERS =================================
    properties (GetAccess = private, SetAccess = private)
        A                   % LHS Matrix
    end
    
    %======================== CONSTRUCTORS ============================
    methods
        function obj = RelaxGaussSeidelOptimized(level)
            % RELAX(LEVEL, OMEGA) initializes a relaxation scheme for the
            % level LEVEL problem with damping parameter OMEGA. If
            % homogeneous = true, relaxation is applied to A*x=0, otherwise
            % to A*x=b.
            obj = obj@amg.relax.Relax(level);
            obj.A = level.A;
        end
    end
    
    %======================== IMPL: Relax =============================
    methods (Sealed)
        function [x, r] = runHomogeneous(obj, x, r, nu)
            % Apply a relaxation sweep with an initial guess X to A*X=0. X
            % can be a matrix whose columns are multiple initial guesses.
            % Assuming X is an error vector, so the corresponding residual
            % is the action A*X.
            [x, r] = gsrelax(obj.A, x, r, uint32(nu))
        end
        
        function [x, r] = runWithRhs(obj, x, r, dummy1, nu) %#ok
            % Apply a relaxation sweep with an initial guess X to A*X=B. X
            % can be a matrix whose columns are multiple initial guesses. B
            % is the corresponding RHS matrix.
            [x, r] = gsrelax(obj.A, x, r, uint32(nu))
        end
    end
end
