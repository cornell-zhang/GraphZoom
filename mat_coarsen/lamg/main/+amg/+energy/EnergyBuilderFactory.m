classdef (Sealed) EnergyBuilderFactory < handle
    %ENERGYBUILDERFACTORY A factory of energy builders.
    %   This class produces ENERGYBUILDER instances.
    %
    %   See also: GRAPH.
    
    %======================== METHODS =================================
    methods
        function instance = newInstance(obj, type, fineLevel, coarseLevel, options) %#ok<MANU>
            % Returns a new generator graph instance based on the input
            % options parsed from VARARGIN.
            switch (type)
                case 'none'
                    % No energy correction is applied, output raw Galerkin operator
                    instance = amg.energy.EnergyBuilderGalerkin(fineLevel, coarseLevel);
                case 'adaptive'
                    % Adaptive RHS energy correction
                    instance = amg.energy.EnergyBuilderAdaptive(fineLevel, coarseLevel);
                case 'flat'
                    % Flat factor energy correction is applied (to RHS
                    % only) from input options
                    instance = amg.energy.EnergyBuilderFlat(fineLevel, coarseLevel, options);
                case 'flat-ls'
                    % Flat factor energy correction is applied (to RHS
                    % only) using LS fit to TV energies
                    instance = amg.energy.EnergyBuilderFlatLs(fineLevel, coarseLevel, options);
                case 'constant'
                    % Output constant*Ac
                    instance = amg.energy.EnergyBuilderConstant(fineLevel, coarseLevel, options.energyCorrectionFactor);
                case 'nodal-rhs'
                    % Fit sum of Ei terms over each aggregate to the
                    % aggregate's EI
                    %instance = amg.energy.EnergyBuilderNodal(fineLevel, coarseLevel, options);
                    instance = amg.energy.EnergyBuilderNodalRhs(fineLevel, coarseLevel, options);
                case 'ls-sum'
                    % Fit sum of Ei terms over each aggregate to the
                    % aggregate's EI
                    instance = amg.energy.EnergyBuilderLsSum(fineLevel, coarseLevel);
                
                case 'nodal'
                    % Fit sum of Ei terms over each aggregate to the
                    % aggregate's EI
                    instance = amg.energy.EnergyBuilderNodal(fineLevel, coarseLevel, options);
                case 'ls-term'
                    % Interpolate individual Ei terms from {EI}_I
                    instance = amg.energy.EnergyBuilderLsTerm(fineLevel, coarseLevel, options);
                otherwise
                    error('MATLAB:EnergyBuilderFactory:newInstance:InputArg', 'Unknown coarse-level energy building strategy ''%s''', type);
            end
        end
    end
    
    %======================== PRIVATE METHODS =========================
end
