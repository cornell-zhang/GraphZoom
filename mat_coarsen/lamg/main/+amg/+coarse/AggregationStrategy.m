classdef (Hidden) AggregationStrategy < amg.api.HasOptions
    %ENERGYBUILDERFACTORY Aggregation strategy operations.
    %   This class is the main delegate of business operations in AGGREGATOR.
    %
    %   See also: AGGREGATOR.
        
    %======================== CONSTRUCTORS ============================
    methods
        function obj = AggregationStrategy(options)
            % Initialize a limited-coarse-set-size aggregation algorithm.
            obj = obj@amg.api.HasOptions(options);
        end
    end
    
    %======================== METHODS =================================
    methods (Abstract)
        instance = newAssociateHolder(obj, n, g)
        % Returns a new association holder that represents the coarsening
        % pattern.
        
        aggregationStage(obj, level, coarseSet, delta, numAssociationSweeps)
        % Purpose: further aggregate the coarse aggregate set defined by
        % seed, using an affinity strength threshold delta Input:
        %      coarseSet = coare set object - passed by reference delta =
        %      affinity strength threshold numSweepsPerAggregation = number
        %      of association-attempt sweeps to perform over coarse set
        %      nodes
        %Output: upon return from this method, coarseSet is updated with
        %the new set of aggregates.
        
        cntinueWhile = aggregateWhileCondition(obj, coarseSet, result, stage)
        % Continue-condition of the main while loop in
        % aggregationStageLoop().
    end
    
    methods
        function b = efficiencyMeasure(obj, acf, cycleIndex, a, nu) %#ok<MANU>
            % Compute the efficiency measure b of a grid with HCR ACF = acf,
            % cycle index cycldeIndex and coarsening ratio a. NU = #relax
            % per cycle.
            %mlAcf   = lacunary(acf, obj.cycleIndex);    % Simulate worst-case
            %scenario of multi-level cycle ACF where errors at all levels
            %reinforce each other. Here we use the ACF formula for #levels=2.
            w       = nu/max(0, 1-cycleIndex*a);    % Estimated multi-level cycle work. Infinite for a >= 1/gamma.
            mlAcf   = 1 - (1-acf)*(1-acf^cycleIndex);   % Worst-case scenario of three-level cycle ACF where errors at all levels reinforce each other: ACF + ACF^(GAMMA) + ACF^(GAMMA^2) + ...
            b       = mlAcf^(1/w);                      % Efficiency measure
        end
    end
    
    %======================== PRIVATE METHODS =========================
end
