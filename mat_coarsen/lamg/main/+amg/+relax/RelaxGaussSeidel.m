classdef (Hidden, Sealed) RelaxGaussSeidel < amg.relax.AbstractRelax
    %RELAXGAUSSSEIDEL Gauss-Seidel relaxation scheme.
    %   This class executes Gauss-Seidel relaxation sweeps in lexicographic
    %   order (A-column order) to the linear system Ax=b.
    %
    %   See also: RELAX.
    
    %======================== CONSTRUCTORS ============================
    methods
        function obj = RelaxGaussSeidel(level, omega, adaptive)
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
            M = tril(A);
        end
    end
end
