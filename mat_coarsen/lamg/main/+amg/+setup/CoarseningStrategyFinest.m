classdef (Hidden, Sealed) CoarseningStrategyFinest < amg.setup.CoarseningStrategy
    %LEVELBUILDER A builder of the finest level.
    %   This class builds the finest level from a Problem object.
    %
    %   See also: MULTILEVELSETUP, COARSENINGSTRATEGY.
    
    %======================== CONSTRUCTORS ============================
    methods
        function obj = CoarseningStrategyFinest(options)
            % Initialize this object.
            obj = obj@amg.setup.CoarseningStrategy(options);
        end
    end
    
    %======================== IMPL: CoarseningStrategy ================
    methods (Access = protected)
        function [coarseLevel, hcr, beta, nu, details] = buildInternal(obj, target, problem, dummy) %#ok
            % Build and return the next-coarser level COARSELEVEL using the
            % strategy encapsulated in this object. FINELEVEL is the
            % coarsest level to date (one above LEVEL).
            coarseLevel = amg.setup.CoarseningStrategy.LEVEL_FACTORY.newInstance(...
                amg.level.LevelType.FINEST, ...
                target.index, ...
                amg.setup.CoarseningState.FINEST, ...
                target.relaxFactory, ...
                min(obj.options.tvMax, obj.options.tvNum), ...
                'name', problem.g.metadata.name, ...
                'A', problem.A, 'g', problem.g, ...
                'options', target.options);
            % Coarsening statistics do not apply here because we only
            % constructed the finest level and didn't really coarsen
            hcr     = [];
            beta    = [];
            nu      = [];
            details = [];
            
            % Update state
            obj.incrementNumAggLevels(target);
            if (obj.options.elimination)
                target.state = amg.setup.CoarseningState.ELIMINATION;
            else
                target.state = amg.setup.CoarseningState.AGG;
            end
        end
    end
    
    %======================== PRIVATE METHODS =========================
end