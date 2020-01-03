classdef (Sealed, Hidden) AggregationStrategyGeometric < amg.coarse.AggregationStrategyFixed
    %AGGREGATORGEOMETRIC Does not aggregate.
    %   This implementation is only suitable for fixed coarsening patterns
    %   (e.g. geometric coarsening).
    %
    %   See also: AGGREGATOR.
    
    
    %======================== PROPERTIES ==============================
    properties (GetAccess = private, SetAccess = private)
        staggering      % Stagger coarse grid nodes or not
        c               % Coarsening ratio
    end
    
    %======================== CONSTRUCTORS ============================
    methods
        function obj = AggregationStrategyGeometric(options, c, staggering)
            % Initialize a limited-coarse-set-size aggregation algorithm.
            obj = obj@amg.coarse.AggregationStrategyFixed(options);
            obj.c = c;
            obj.staggering = staggering;
        end
    end
    
    %======================== IMPL: AbstractAggregator ================
    methods
        function instance = newAssociateHolder(obj, n, g)
            % Returns a new association holder that represents a geometric
            % coarsening pattern. Geometric semi-coarsening along the first
            % dimension x for grid graphs. No need to compute affinities.
            % Directly inject seeds/aggregate index
            
            % Construct node index->seed index mapping
            H           = repmat(g.metadata.attributes.h, n, 1);
            index       = round((g.coord+0.5*H)./H);
            C           = repmat(obj.c,n,1);
            
            if (obj.staggering)
                % Staggering - works only in 2-D with c = [2 1] for now
                i = index-mod([index(:,1)+index(:,2)-1 index(:,1)]+C-1,C);
                i(i(:,1) == 0, 1) = 1;
            else
                % No staggering
                i           = index-mod(index+C-1,C); % Coarsen in all directions by the appropriate factors
            end
            
            seed            = sub2indm(g.metadata.attributes.n, i)';
            numAggregates   = numel(unique(seed));
            
            % Populate target object
            instance    = amg.coarse.AssociateHolder.newFixedPattern(...
                 numAggregates, seed);
        end
    end
end
