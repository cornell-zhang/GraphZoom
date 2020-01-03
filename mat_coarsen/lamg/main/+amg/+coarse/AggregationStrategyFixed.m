classdef (Hidden) AggregationStrategyFixed < amg.coarse.AggregationStrategy
    %AGGREGATORGEOMETRIC Does not aggregate.
    %   This implementation is only suitable for fixed coarsening patterns
    %   (e.g. geometric coarsening).
    %
    %   See also: AGGREGATOR.
    
    %======================== CONSTRUCTORS ============================
    methods
        function obj = AggregationStrategyFixed(options)
            % Initialize a limited-coarse-set-size aggregation algorithm.
            obj = obj@amg.coarse.AggregationStrategy(options);
        end
    end
    
    %======================== IMPL: AbstractAggregator ================
    methods (Sealed)
        function cntinueWhile = aggregateWhileCondition(obj, dummy1, dummy2, stage) %#ok
            % Continue-condition of the main while loop in
            % aggregationStageLoop(). Force a single stage.
            cntinueWhile = (stage < 1);
        end
        
        function aggregationStage(obj, dummy1, dummy2, dummy3, dummy4) %#ok
            % The single aggregation stage in which COARSESET is set to the
            % geometric coarsening aggregate set. This is a dummy stage,
            % since coarseSet is already populated.
        end
    end
end
