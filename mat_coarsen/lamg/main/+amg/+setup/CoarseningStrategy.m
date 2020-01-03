classdef CoarseningStrategy < amg.api.HasOptions & amg.api.Builder
    %LEVELBUILDER A builder of the next coarsening level.
    %   This class builds the next coarser level during the multilevel
    %   setup phase, given the current (coarsest to date) level. It serves
    %   as the state handler of a MultilevelSetup during the setup phase
    %   main loop.
    %
    %   See also: MULTILEVELSETUP.
    
    %=========================== PROPERTIES ==============================
    properties (Constant, GetAccess = private)
        logger = core.logging.Logger.getInstance('amg.setup.CoarseningStrategy')
    end
    properties (Constant, GetAccess = protected)
        LEVEL_FACTORY = amg.level.LevelFactory
    end
    
    %======================== CONSTRUCTORS ============================
    methods
        function obj = CoarseningStrategy(options)
            % Initialize this object to the initial
            obj = obj@amg.api.HasOptions(options);
        end
    end
    
    %======================== METHODS =================================
    methods (Sealed)
        function  [coarseLevel, hcr, beta, nu, details] = build(obj, target, problem, fineLevel)
            % Build and return the next-coarser level COARSELEVEL using the
            % strategy encapsulated in this object. FINELEVEL is the
            % coarsest level to date (one above LEVEL). TARGET is the
            % owning MULTILEVELSETUP object whose state this is. A template
            % method.
            
            [coarseLevel, hcr, beta, nu, details] = buildInternal(obj, target, problem, fineLevel);
            
            % Return the next coarsening state of MultilevelSetup after
            % this object's build() method is called. FINELEVEL is the
            % coarsest level to date (i.e. the return value of BUILD()).
            % This method also updates the internal state of this object.
            if (~obj.canCoarsen(target, coarseLevel))
                target.state = amg.setup.CoarseningState.DONE_COARSENING;
            end
            if (isempty(coarseLevel))
                if (obj.logger.debugEnabled)
                    obj.logger.debug('Empty level, skipping it\n');
                end
            else
                target.index = target.index + 1;
            end
        end
    end
    
    %======================== PRIVATE METHODS =========================
    methods (Access = protected, Abstract)
        [coarseLevel, hcr, beta, nu, details] = buildInternal(obj, target, problem, fineLevel)
        % Internal call. Build and return the next-coarser level
        % COARSELEVEL using the strategy encapsulated in this object.
        % FINELEVEL is the coarsest level to date (one above LEVEL). TARGET
        % is the owning MULTILEVELSETUP object whose state this is.
    end
    
    methods (Access = protected, Sealed)
        function incrementNumAggLevels(obj, target) %#ok<MANU>
            % Increment the # of AGG levels maintained by this object.
            target.numAggLevels = target.numAggLevels + 1;
        end
        
        function result = canCoarsen(obj, target, level)
            % Decide whether the current level (level) can be further
            % coarsened based on the input options.
            
            % * #levels exceeded, can't further coarsen
            % * A is completely zero, no need to further coarsen
            % * level is coarse,  no need to further coarsen
            if (~isempty(level))
                if (target.numAggLevels == obj.options.setupNumAggLevels)
                    if (obj.logger.debugEnabled)
                        obj.logger.debug('Reached maximum allowed AGG levels\n');
                    end
                    result = false;
                    return;
                elseif (target.index == obj.options.setupNumLevels)
                    if (obj.logger.debugEnabled)
                        obj.logger.debug('Reached maximum allowed setup levels\n');
                    end
                    result = false;
                    return;
                elseif (level.zeroMatrix || (level.g.numNodes < obj.options.maxDirectSolverSize))
                    if (obj.logger.debugEnabled)
                        obj.logger.debug('Reached a small enough graph (< %d)\n', obj.options.maxDirectSolverSize);
                    end
                    result = false;
                    return;
                end
            end
            
            if (isempty(level))
                % No level was constructed in the last coarsening strategy
                % handler ==> must coarsen.
                %
                % Level has 0-degree nodes ==> relaxation is ill-defined
                % and we must turn to elimination
                result = true;
                return;
            end
            
            %result = obj.isRelaxationFast(level);
            result = true;
        end
    end
end