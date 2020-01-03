classdef (Hidden, Sealed) RelaxSymmetricGaussSeidel < amg.relax.AbstractRelax
    %RELAXSYMMETRICGAUSSSEIDEL Symmetric Gauss-Seidel relaxation scheme.
    %   This class executes a symmetric Gauss-Seidel relaxation sweep
    %   (forward LEX, then backward LEX) to the linear system Ax=b.
    %
    %   See also: RELAX.
    
    %======================== CONSTRUCTORS ============================
    methods
        function obj = RelaxSymmetricGaussSeidel(level, omega, adaptive)
            % RelaxGaussSeidel(level) constructs a damped GS relaxation
            % scheme for the level LEVEL problem.
            obj = obj@amg.relax.AbstractRelax(level, [], [], omega, adaptive);
        end
    end
    
    %======================== IMPL: Relax =============================
    methods (Access = protected)
        function M = getM(obj, A) %#ok<MANU>
            % Compute the backward stencil matrix M of the relaxation
            % scheme for Ax=b.
            D = diag(diag(A));
            L = tril(A);
            U = triu(A);
            M = L*(D\U);
        end
    end
end

