classdef (Hidden, Sealed) EnergyBuilderGalerkin < amg.energy.EnergyBuilder
    %ENERGYBUILDERGALERKIN A trivial coarse-level energy builder.
    %   This implementation returns the coarse-level Galerkin operator
    %   as-is (no energy correction).
    %
    %   See also: LEVEL, ENERGYBUILDER, ENERGYBUILDERFACTORY.
    
    %======================== CONSTRUCTORS ============================
    methods
        function obj = EnergyBuilderGalerkin(fineLevel, coarseLevel)
            % Initialize a local-sum-LS energy correction.
            options.energyOutFile = [];
            obj = obj@amg.energy.EnergyBuilder(fineLevel, coarseLevel, options);
        end
    end
        
    %======================== IMPL: EnergyBuilder =====================
    methods (Access = protected)
        function Ac = doBuildEnergy(obj)
            % Return the coarse-level Galerkin operator Ac intact.
            Ac = obj.coarseLevel.A;
        end
    end
end
