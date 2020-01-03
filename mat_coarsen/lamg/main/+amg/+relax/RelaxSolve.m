classdef (Sealed) RelaxSolve < amg.api.IterativeMethod
    %RELAXSOLVE relaxation scheme for solving A*x=b for zero-row-sum A.
    %   This is a relaxation decorator that subtracts the mean of x from x
    %   after each relaxation sweep.
    
    %======================== MEMBERS =================================
    properties (GetAccess = private, SetAccess = private)
        relax               % The relaxation scheme
    end
    
    %======================== CONSTRCUTORS ============================
    methods
        function obj = RelaxSolve(relax)
            % Wrap a an iterative method RELAX with this decorator.
            %obj = obj@amg.api.IterativeMethod();
            obj.relax = relax;
        end
    end
    
    %======================== IMPL: IterativeMethod ===================
    methods (Sealed)
        function x = run(obj, xold, iterateHistory)
            % Apply a relaxation sweep followed by subtracting the mean of x.
            x = obj.relax.run(xold, iterateHistory);
            x = x - repmat(mean(x), [size(x,1) 1]);
        end
    end
end

