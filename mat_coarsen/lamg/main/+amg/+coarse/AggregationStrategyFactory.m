classdef (Sealed, Hidden) AggregationStrategyFactory < handle
    %ENERGYBUILDERFACTORY A factory of energy builders.
    %   This class produces ENERGYBUILDER instances.
    %
    %   See also: GRAPH.
    
    %======================== METHODS =================================
    methods
        function instance = newInstance(obj, type, options) %#ok<MANU>
            % Returns a new Aggregation strategy instance based on input
            % options
            switch (type)
                case 'hcr'
                    % HCR-guided aggregation
                    instance = amg.coarse.AggregationStrategyStagewise(options);
                case 'stagewise'
                    % Coarse grid limited to a certain coarsening ratio
                    instance = amg.coarse.AggregationStrategyLimited(options);
                case 'limited'
                    % Coarse grid limited to a certain coarsening ratio
                    instance = amg.coarse.AggregationStrategyLimited(options);
                case 'geometric'
                    % Full geometric coarsening for grid graphs
                    instance = amg.coarse.AggregationStrategyGeometric(options, options.coarseningRatio, false);
                case 'staggered'
                    % Staggered 2-D 2:1 geometric coarsening for 2-D grid
                    % graphs
                    instance = amg.coarse.AggregationStrategyGeometric(options, [2 1], true);
                otherwise
                    error('MATLAB:AggregationStrategyFactory:newInstance:InputArg', 'Unknown aggregation strategy ''%s''',type);
            end
        end
    end
    
    %======================== PRIVATE METHODS =========================
end
