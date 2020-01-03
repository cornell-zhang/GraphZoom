classdef (Hidden, Sealed) EnergyBuilderAdaptive < amg.energy.EnergyBuilder
    %ENERGYBUILDERGALERKIN Adaptive nodal energy fitting.
    %   This implementation returns the coarse-level Galerkin operator
    %   as-is (no energy correction).
    %
    %   See also: LEVEL, ENERGYBUILDER, ENERGYBUILDERFACTORY.
    
    %======================== CONSTRUCTORS ============================
    methods
        function obj = EnergyBuilderAdaptive(fineLevel, coarseLevel)
            % Initialize a local-sum-LS energy correction.
            options.energyOutFile = [];
            obj = obj@amg.energy.EnergyBuilder(fineLevel, coarseLevel, options);
        end
    end
    
    %======================== IMPL: EnergyBuilder =====================
    methods
        function mu = adaptiveRhsCorrection(obj, x, xc)
            % Adaptive RHS correction, if this is an adaptive strategy. For
            % non-adaptive strategies, return an empty array. Adaptive
            % nodal energy fitting
            % http://bamg.pbworks.com/w/page/38269196/Adapt
            % ive-Nodal-Energy-Fitting            
            Ax      = obj.fineLevel.A*x;
            Efine   = obj.coarseLevel.R * (x.*Ax - 0.5*(obj.fineLevel.A*x.^2));
            Ac      = obj.coarseLevel.A;
            Ecoarse = xc.*(Ac*xc) - 0.5*(Ac*xc.^2);
            %mu      = (norm(xc)/norm(x)).^2 * Efine ./ Ecoarse;
            mu      = Efine ./ Ecoarse;
        end
    end
    
    methods (Access = protected)
        function Ac = doBuildEnergy(obj)
            % Return the coarse-level Galerkin operator Ac intact.
            Ac = obj.coarseLevel.A;
        end
    end
end
