classdef (Hidden, Sealed) RelaxGaussSeidelRandom < amg.relax.AbstractRelax
    %RELAXGAUSSSEIDEL Gauss-Seidel relaxation scheme with random ordering.
    %   This class executes Gauss-Seidel relaxation sweeps in a random
    %   order (A-column order) to the linear system Ax=b. The order is
    %   determined upon constructing this object and used consistently in
    %   every subsequent GS sweep.
    %
    %   See also: RELAX.
    
    %======================== CONSTRUCTORS ============================
    methods
        function obj = RelaxGaussSeidelRandom(level, omega, adaptive)
            % RelaxGaussSeidel(level) constructs a damped GS relaxation
            % scheme for the level LEVEL problem.
            
            % Generate random permutation of A's rows
            order   = randperm(level.size);
            E       = speye(level.size);
            E       = E(:,order);
            obj = obj@amg.relax.AbstractRelax(level, E', E, omega, adaptive);
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

