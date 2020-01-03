classdef Relax < amg.api.IterativeMethod & amg.level.SingleLevelOperator
    %RELAX relaxation scheme.
    %   This is an interface for all damped relaxation methods of the type
    %
    %       M*X + N*XOLD = B XNEW = (1-w)*XOLD + w*X
    %
    %   to solve the level LEVEL problem A*X=B, where A=M+N is the method's
    %   splitting and omega is the damping parameter.
    %
    %   See also: LHSVECTOR.
    
    %======================== CONSTRCUTORS ============================
    methods (Access = protected)
        function obj = Relax(level)
            % RELAX(LEVEL) initializes a relaxation scheme for the level
            % LEVEL problem.
            obj = obj@amg.level.SingleLevelOperator(level);
        end
    end
    
    %======================== IMPL: IterativeMethod ===================
    methods
        function [x, r] = run(obj, x, r)
            % Apply one relaxation sweep with an initial guess X to A*X=0.
            % X can be a matrix whose columns are multiple initial guesses.
            [x, r] = obj.runHomogeneous(x, r, 1);
        end
    end
    
    %======================== METHODS =================================
    methods (Abstract)
        [x, r] = runHomogeneous(obj, x, r, nu)
        % Apply NU relaxation sweeps with an initial guess LhsVector X to A*X=0. X
        % can be a matrix whose columns are multiple initial guesses.
        % Assuming X is an error vector, so the corresponding residual is
        % -A*X.
        
        [x, r] = runWithRhs(obj, x, r, b, nu)
        % Apply NU relaxation sweeps with an initial guess LhsVector X to A*X=B. X
        % can be a matrix whose columns are multiple initial guesses. B is
        % the corresponding RHS matrix.
    end
end
