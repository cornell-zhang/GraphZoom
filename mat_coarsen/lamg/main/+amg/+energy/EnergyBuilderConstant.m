classdef (Hidden, Sealed) EnergyBuilderConstant < amg.energy.EnergyBuilder
    %ENERGYBUILDERCONSTANT Constant energy correction.
    %   This implementation returns the coarse-level Galerkin operator
    %   multiplied by a global constant ALPHA.
    %
    %   See also: LEVEL, ENERGYBUILDER, ENERGYBUILDERFACTORY.
    
    %======================== IMPL: EnergyBuilder =====================
    properties (GetAccess = private, SetAccess = private)
        alpha           % Global multiplier
    end
    
    
    %======================== CONSTRUCTORS ============================
    methods
        function obj = EnergyBuilderConstant(fineLevel, coarseLevel, alpha)
            % Initialize a constant energy correction with multiplier
            % alpha.
            obj = obj@amg.energy.EnergyBuilder(fineLevel, coarseLevel, []);
            obj.alpha = alpha;
        end
    end

    %======================== IMPL: EnergyBuilder =====================
    methods (Access = protected)
        function Ac = doBuildEnergy(obj)
            % Return alpha*Ac.
            Ac = obj.alpha * obj.coarseLevel.A;
        end
    end
end
