classdef (Hidden, Sealed) RelaxJacobi < amg.relax.AbstractRelax
    %RELAXJACOBI Weighted Jacobi relaxation scheme.
    %   This class executes weighted Jacobi relaxation sweeps to the linear
    %   system Ax=b.
    %
    %   See also: RELAX.
    
    %======================== CONSTRUCTORS ============================
    methods
        function obj = RelaxJacobi(level, omega, adaptive)
            % RelaxJacobi(level, omega) constructs an dampled Jacobi
            % relaxation scheme for the level LEVEL problem.
            obj = obj@amg.relax.AbstractRelax(level, [], [], omega, adaptive);
        end
    end
    
    %======================== IMPL: Relax =============================
    methods (Access = protected)
        function M = getM(obj, A) %#ok<MANU>
            % Compute the backward stencil matrix M of the relaxation
            % scheme for Ax=b.
            M = diag(diag(A));
        end
    end
end
