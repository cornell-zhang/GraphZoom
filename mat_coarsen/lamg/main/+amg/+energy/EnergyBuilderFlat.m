classdef (Hidden) EnergyBuilderFlat < amg.energy.EnergyBuilder
    %ENERGYBUILDERGALERKIN Flat factor coarse-level energy builder.
    %   This implementation returns the coarse-level Galerkin operator
    %   as-is (no energy correction) and a constant RHS correction factor
    %   mu.
    %
    %   See also: LEVEL, ENERGYBUILDER, ENERGYBUILDERFACTORY.
    
    %======================== CONSTRUCTORS ============================
    methods
        function obj = EnergyBuilderFlat(fineLevel, coarseLevel, options)
            % Initialize a flat factor energy corrector.
            obj = obj@amg.energy.EnergyBuilder(fineLevel, coarseLevel, options);
        end
    end
    
    %======================== IMPL: EnergyBuilder =====================
    methods (Sealed, Access = protected)
        function Ac = doBuildEnergy(obj)
            % Return the coarse-level Galerkin operator Ac intact.
            Ac = obj.coarseLevel.A;
        end
    end
    
    methods (Access = protected)
        function mu = doBuildRhsCorrection(obj)
            % Calculate RHS energy correction factor MU. In principle,
            % should optimize their value at every level as explained in
            % http://bamg.pbworks.com/w/page/37946021/Flat-Energy-Correctio
            % n . For now, setting to same factor input options at all
            % levels.
            mu = obj.options.rhsCorrectionFactor;
        end
    end
end
