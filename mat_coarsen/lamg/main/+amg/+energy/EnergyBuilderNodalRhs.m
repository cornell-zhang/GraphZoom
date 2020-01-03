classdef (Hidden, Sealed) EnergyBuilderNodalRhs < amg.energy.EnergyBuilder
    %ENERGYBUILDERLSSUM Energy correction using local-term-sum
    %least-squares.
    %   This implementation builds a coarse-level energy as a sum of EI
    %   terms; each EI is fit (for TVs) in least-squares sense to the local
    %   sum of fine energy terms ei over each aggregate I.
    %
    %   See also: LEVEL, ENERGYBUILDER, ENERGYBUILDERFACTORY.
    
    %======================== IMPL: EnergyBuilder =====================
    properties (Constant, GetAccess = private)
        myLogger = core.logging.Logger.getInstance('amg.energy.EnergyBuilderNodal')
    end
    
    %======================== CONSTRUCTORS ============================
    methods
        function obj = EnergyBuilderNodalRhs(fineLevel, coarseLevel, options)
            % Initialize a local-sum-LS energy correction.
            obj = obj@amg.energy.EnergyBuilder(fineLevel, coarseLevel, options);
        end
    end
    
    %======================== IMPL: EnergyBuilder =====================
    methods (Access = protected)
        function Ac = doBuildEnergy(obj)
            % Return the coarse-level Galerkin operator Ac intact.
            Ac = obj.coarseLevel.A;
        end
        
        function mu = doBuildRhsCorrection(obj)
            % Fit RHS energy correction factor MU to TV energy
            % discrepancies in LS sense.
            
            X   = obj.fineLevel.x;
            A   = obj.fineLevel.A;
            E   = obj.coarseLevel.restrict(X .* (A * X) - 0.5 * (A * X.^2));
            Y   = obj.coarseLevel.T * X;
            AC  = obj.coarseLevel.A;
            Ec  = Y .* (AC * Y) - 0.5 * (AC * Y.^2);
            ratio = Ec./E;
            ratio(E == 0) = 0; % If E=0, omit corresponding Ec term from coarse RHS
            mu  = mean(ratio, 2);
        end
    end
end
