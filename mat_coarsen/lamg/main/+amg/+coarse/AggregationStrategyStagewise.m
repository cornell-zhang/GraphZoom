classdef (Hidden) AggregationStrategyStagewise < amg.coarse.AggregationStrategy
    %ABSTRACTAGGREGATOR Stagewise aggregation.
    %   This implementation selects the coarse level by constructing a set
    %   of increasingly-dense tentative coarse sets, and selecting the set
    %   that minimizes the HCR ACF per unit work among them.
    %
    %   See also: AGGREGATOR, AGGREGATIONSTRATEGY.
    
    
    %=========================== PROPERTIES ==============================
    properties (Constant, GetAccess = private)
        logger          = core.logging.Logger.getInstance('amg.coarse.AggregationStrategyStagewise')
    end
    
    properties (GetAccess = private, SetAccess = private)
        numPrintoutLines = 10   % Resolution of progress bar
    end
    
    %======================== CONSTRUCTORS ============================
    methods
        function obj = AggregationStrategyStagewise(options)
            % Initialize a limited-coarse-set-size aggregation algorithm.
            obj = obj@amg.coarse.AggregationStrategy(options);
        end
    end
    
    %======================== IMPL: AggregationStrategy ===============
    methods
        function instance = newAssociateHolder(dummy1, n, dummy2, dummy3) %#ok
            % Empty holder. Will be populated by aggregationStage() calls.
            instance = amg.coarse.AssociateHolder.newEmpty(n);
        end
        
        function cntinueWhile = aggregateWhileCondition(obj, coarseSet, result, stage)
            % Continue-condition of the main while loop in
            % aggregationStageLoop().
            cntinueWhile = (coarseSet.numAggregates > obj.options.minCoarseSize) && ...
                (coarseSet.numAggregates >= coarseSet.numNodes*obj.options.minCoarseningRatio) && ...
                (stage < obj.options.maxAggregationStages) && ...
                ((stage < obj.options.minAggregationStages) || ...
                ~result.betaIncreased(stage, obj.options.betaIncreaseTol));
        end
        
        function aggregationStage(obj, dummy1, coarseSet, delta) %#ok
            % Purpose: further aggregate the coarse aggregate set defined
            % by seed, using an affinity strength threshold delta Input:
            %      coarseSet = coare set object - passed by reference delta
            %      = affinity strength threshold numSweepsPerAggregation =
            %      number of association-attempt sweeps to perform over
            %      coarse set nodes
            %Output: upon return from this method, coarseSet is updated
            %with the new set of aggregates.
            
            % Initializations
            n               = coarseSet.numNodes;
            alphaThreshold  = obj.options.minCoarseningRatio*n;
            strictRatio     = obj.options.strictMinCoarseningRatio;
            % A boolean array indicating whether a seed was visited in the current association sweep or not.
            visited         = false(1, n);
            %visited(coarseSet.isSeed) = false;                      %
            %Reset all seeds to non-visited  - not needed in single
            %association sweep setting
            seeds           = find(coarseSet.isSeed);
            
            numSeeds = numel(seeds);
            fraction = round(numSeeds/obj.numPrintoutLines);
            if (obj.logger.debugEnabled)
                obj.logger.debug('Association sweep #%d\n', stage);
                tstart = tic;
            end
            
            for j = 1:numSeeds %i = seeds                           % Note: make sure the seeds array is copied by value to a working copy before this loop, because it changes during the loop
                i = seeds(j);
                if ((mod(j, fraction) == 0) && obj.logger.debugEnabled)
                    tElapsed = toc(tstart);
                    obj.logger.debug('Finished %.f%%  %d/%d in %.2f sec [%.2g sec/node]\n', ...
                        (100.*j)/numSeeds, j, numSeeds, tElapsed, (1.0*tElapsed)/j);
                    tstart = tic;
                end
                if (~visited(i))                          % seed i hasn't yet been visited during this sweep
                    visited(i) = true;
                    s = coarseSet.bestSeed(i, delta);
                    if (s > 0)
                        % There exists an affinitive neighbor s to
                        % associate i with
                        coarseSet.addNodeToAggregate(i, s);
                        visited(s) = true;                % Prevent visiting the seed again during this sweep
                        if (strictRatio && (coarseSet.numAggregates <= alphaThreshold))
                            % If reached alpha threshold in the middle of
                            % an association sweep, terminate it
                            break;
                        end
                    end
                end
            end
        end
    end
end
