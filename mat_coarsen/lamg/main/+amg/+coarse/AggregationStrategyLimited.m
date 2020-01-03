classdef (Hidden, Sealed) AggregationStrategyLimited < amg.coarse.AggregationStrategyStagewise
    %ABSTRACTAGGREGATOR Aggregation up to a prescribed coarsening ratio.
    %   This implementation selects the coarse level by constructing a set
    %   of increasingly-dense tentative coarse sets, gradually decreasing
    %   the affinity threshold, delta. When OBJ.OPTIONS.minCoarseningRatio
    %   is reached, aggregation terminates and the coarse set is output.
    %
    %   See also: AGGREGATOR.
    
    %======================== CONSTRUCTORS ============================
    methods
        function obj = AggregationStrategyLimited(options)
            % Initialize a limited-coarse-set-size aggregation algorithm.
            obj = obj@amg.coarse.AggregationStrategyStagewise(options);
        end
    end
    
    %======================== IMPL: Aggregator ========================
    methods
        function instance = newAssociateHolder(dummy1, dummy2, dummy3, dummy4) %#ok
            % Empty holder. Will be populated by aggregationStage() calls.
            instance = [];
        end
        
        function cntinueWhile = aggregateWhileCondition(obj, coarseSet, dummy1, stage) %#ok
            % Continue-condition of the main while loop in
            % aggregationStageLoop().
            nc = coarseSet.numAggregates;
            n = coarseSet.numNodes;
            maxCoarseningRatio = obj.options.coarseningWorkGuard/obj.options.cycleIndex;
            cntinueWhile = (stage < obj.options.minAggregationStages) || ((nc >= n*maxCoarseningRatio) && (stage < obj.options.maxAggregationStages));
        end
        
        function b = efficiencyMeasure(obj, dummy1, dummy2, a, dummy3) %#ok
            % Compute the efficiency measure b of a grid with HCR ACF =
            % acf, cycle index cycldeIndex and coarsening ratio a. NU =
            % #relax per cycle.
            %mlAcf   = lacunary(acf, obj.cycleIndex);    % Simulate
            %worst-case scenario of multi-level cycle ACF where errors at
            %all levels reinforce each other. Here we use the ACF formula
            %for #levels=2.
            
            %w       = nu/max(0, 1-cycleIndex*a);    % Estimated
            %multi-level cycle work. Infinite for a >= 1/gamma.
            % Bias ACF to accept the largest a for which acf <= maxHcrAcf
            %if ((a < obj.options.minCoarseningRatio) || (a >
            %obj.maxCoarseningRatio) || (acf > obj.options.maxHcrAcf))
            % 7-MAY-2011: deciding based on a alone, not on HCR rate, which
            % is anyway not very meaningful for caliber-1 P and adds to the
            % setup cost
            %            if ((a < obj.options.minCoarseningRatio) || (a >
            %            obj.maxCoarseningRatio) || (acf >
            %            obj.options.maxHcrAcf))
            
            maxCoarseningRatio = obj.options.coarseningWorkGuard/obj.options.cycleIndex;
            %if ((a < obj.options.minCoarseningRatio) || (a > obj.maxCoarseningRatio))
%             if (a < obj.options.minCoarseningRatio)
%                 b = 1000;  % Unacceptably-small coarse level
%             else
            if (a > maxCoarseningRatio)
                b = 1+a;   % Unacceptably-large coarse level, bias towards a smaller a
            else
                b = 1-a; % Biases towards a larger a
            end
        end
        
    end
end
