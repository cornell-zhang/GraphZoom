classdef (Hidden, Sealed) EnergyBuilderFlatLs < amg.energy.EnergyBuilderFlat
    %ENERGYBUILDERGALERKINLS Flat factor coarse-level energy builder using
    %LS fit to TV energies.
    %   This implementation returns the coarse-level Galerkin operator
    %   as-is (no energy correction) and a constant RHS correction factor
    %   mu.
    %
    %   See also: LEVEL, ENERGYBUILDER, ENERGYBUILDERFACTORY.
    
    %======================== CONSTRUCTORS ============================
    methods
        function obj = EnergyBuilderFlatLs(fineLevel, coarseLevel, options)
            % Initialize a flat factor energy corrector.
            obj = obj@amg.energy.EnergyBuilderFlat(fineLevel, coarseLevel, options);
        end
    end
    
    %======================== IMPL: EnergyBuilder =====================
    methods (Access = protected)
        function mu = doBuildRhsCorrection(obj)
            % Fit RHS energy correction factor MU to TV energy
            % discrepancies in LS sense.
            E   = obj.tvEnergyFine;
            Ec  = obj.tvEnergyCoarse;
            %mu  = ones(numel(E),1) \ (Ec./E);
            mu  = mean(Ec./E);
        end
    end
end
