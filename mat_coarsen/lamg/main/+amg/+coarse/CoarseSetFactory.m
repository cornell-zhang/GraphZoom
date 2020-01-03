classdef (Sealed, Hidden) CoarseSetFactory < handle
    %ENERGYBUILDERFACTORY A factory of coarse sets.
    %   This class produces COARSESET instances. A COARSESET determines the
    %   algorithm for updating TVs and affinities during an aggregation
    %   stage.
    %
    %   See also: COARSESET.
    
    %======================== METHODS =================================
    methods
        function instance = newInstance(obj, type, level, associationHolder, options) %#ok<MANU>
            % Returns a new CoarseSet instance based on input options.
            switch (type)
                case 'affinity'
                    % Affinities are held in a matrix and updated with each
                    % aggregation & TV update
                    instance = amg.coarse.CoarseSetAffinityMatrix(level, associationHolder, options);
                case 'recompute'
                    % Affinities are recomputed at each i before finding
                    % its best seed.
                    instance = amg.coarse.CoarseSetAffinityRecompute(level, associationHolder, options);
                case 'energy-min'
                    % Energy-ratio-minimization-based coarsening.
                    instance = amg.coarse.CoarseSetEnergyMin(level, associationHolder, options);
                case 'local-relax'
                    % Local relaxation on TVs at each considered associate
                    % i; TV values are restored to their original values
                    % after i's decision. Affinities are computed
                    % on-the-fly
                    instance = amg.coarse.CoarseSetLocalRelax(level, associationHolder, options);
                case 'affinity-energy'
                    % Combined strategy: affinity- and energy-ratio-minimization-based coarsening.
                    instance = amg.coarse.CoarseSetAffinityEnergy(level, associationHolder, options);
                case 'affinity-energy-mex'
                    % Combined strategy: affinity- and energy-ratio-minimization-based coarsening.
                    % Uses MEX implementation for main aggregation loop.
                    instance = amg.coarse.CoarseSetAffinityEnergyMex(level, associationHolder, options);
                otherwise
                    error('MATLAB:CoarseSetFactory:newInstance:InputArg', 'Unknown aggregation update type ''%s''',type);
            end
        end
    end
    
    %======================== PRIVATE METHODS =========================
end
