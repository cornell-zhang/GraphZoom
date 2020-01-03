classdef (Sealed) Aggregator < amg.api.HasOptions
    %AGGREGATOR Coarse-level set selection (aggregation).
    %   This is a base interface for all implementations of constructing
    %   the coarse-level set of aggregates of a fine level.
    %
    %   See also: LEVEL.
    
    %=========================== PROPERTIES ==============================
    properties (Constant, GetAccess = private)
        logger          = core.logging.Logger.getInstance('amg.coarse.Aggregator')
        AGGREGATION_STRATEGY_FACTORY = amg.coarse.AggregationStrategyFactory
        COARSE_SET_FACTORY = amg.coarse.CoarseSetFactory
    end
    
    properties (GetAccess = private, SetAccess = private)
        aggregationStrategy     % Encapsulates aggregation business logic
        %acfComputer             % Computes HCR ACF, conveniently cached
        figNum = 1000 % Figure counter
    end
    
    %======================== CONSTRUCTORS ============================
    methods
        function obj = Aggregator(options)
            % Initialize an aggregation algorithm.
            obj = obj@amg.api.HasOptions(options);
            obj.options.minAggregationStages = min(...
                obj.options.minAggregationStages, obj.options.maxAggregationStages);
%             obj.acfComputer = lin.api.AcfComputer('maxIterations', obj.options.maxHcrSweeps, ...
%                 'output', 'full', 'steadyStateTol', 1e-2, 'sampleSize', 2);
            obj.aggregationStrategy = amg.coarse.Aggregator.AGGREGATION_STRATEGY_FACTORY.newInstance(options.aggregationType, options);
        end
    end
    
    %======================== IMPL: Aggregator ========================
    methods (Sealed)
        function result = aggregate(obj, level, cycleIndex)
            % Return the coarse variable type operator T (NxNC), which
            % represents a coarse set of level LEVEL node aggregates, for
            % the cycle index design value CYCLEINDEX. This is a template
            % method that relies on obj.seedAggregator during each
            % coarsening stage.
            
            if (obj.logger.debugEnabled)
%                 obj.logger.debug('### Aggregation: gamma = %.1f, nu = %d ###\n', ...
%                     obj.options.cycleIndex, obj.options.nuDefault);
                obj.logger.debug('### Aggregation: gamma = %.1f ###\n', ...
                    obj.options.cycleIndex);
            end
            % Initialize an empty coarse set
            associateHolder = obj.aggregationStrategy.newAssociateHolder(...
                level.g.numNodes, level.g);
            coarseSet       = amg.coarse.Aggregator.COARSE_SET_FACTORY.newInstance(...
                obj.options.aggregationUpdate, level, associateHolder, obj.options);
            x0 = [];
            %x0          = randInRange(-1, 1, level.size, 1);
            %x0          = level.x(:,1);     % TV may probably a better HCR
            %initial guess than random, but this is not clear yet
            
            % First, optimize coarse set with fixed nu
            result = obj.aggregationStageLoop(level, cycleIndex, ...
                obj.options.nuDefault, ...
                coarseSet, x0);
            if (~isempty(result))
                [optimalIndex, T] = result.optimalResult();
            end
            if (~obj.options.nuOptimization || isempty(result))
                % No nu optimization was requested, or no grid was found
                % ==> don't optimize nu
                return;
            end
            
            % For the optimal coarse set, optimize nu
            result = obj.nuLoop(level, cycleIndex, ...
                obj.options.nuMin, obj.options.nuMax, obj.options.nuDefault, ...
                T, x0, result.acf(optimalIndex), result.beta(optimalIndex), coarseSet);
        end
    end
    
    %======================== PRIVATE METHODS =========================
    methods (Access = private)
        function result = aggregationStageLoop(obj, level, cycleIndex, nu, coarseSet, dummy) %#ok
            %-----------------------------------------
            % Loop over coarsening stages
            %-----------------------------------------
            
            % Initializations
            result      = amg.coarse.ResultBundle(level, cycleIndex);
            stage       = 0;    % Stage counter
            
            % Break if beta increases twice in a row
            while (obj.aggregationStrategy.aggregateWhileCondition(coarseSet, result, stage))
                % Create new coarse set
                stage               = stage + 1;
                [delta, ratioMax]   = coarseSet.delta(stage, obj.options);
                if (obj.logger.traceEnabled)
                    obj.logger.trace('Coarsening stage #%d, delta = %.2e\n', stage, delta);
                    disp(coarseSet);
                end
                %obj.aggregationStrategy.aggregationStage(level, coarseSet,
                %delta);
                coarseSet.aggregationStage(delta, ratioMax);
                
                % Add HCR stats to result bundle
                T   = coarseSet.typeOperator;
                % --- not currently in use for caliber-1 P ---
                %[acf, x0]   = obj.measureHcrPerformance(level, nu, T, x0);
                acf = 0;
                b   = obj.aggregationStrategy.efficiencyMeasure(acf, cycleIndex, coarseSet.coarseningRatio, nu);
                
%                 % Debugging: remove a node at the end of the first stage
%                 if ((stage == 5) && ~isempty(obj.options.coarseningDebugNodeIndex))
%                     for i = obj.options.coarseningDebugNodeIndex
%                         coarseSet.detachNode(i);
%                     end
%                     T           = coarseSet.typeOperator;
%                     b = 0;
%                 end

                result.addResult(stage, T, coarseSet.aggregateIndex, nu, acf, b);
                %                 % Add TV (before coarsening) to level and
                %                 (after % coarsening) to coarseSet if
                %                 (obj.options.addHcrVectors)
                %                     coarseSet.addTv(T, x0);
                %                 end
                
                if (obj.logger.debugEnabled)
                    obj.logger.debug('Stage %2d     nc = %-5d alpha = %.2f   beta = %.2f   delta = %.2e  d/(1+d)=%.2f\n', ...
                        stage, size(T,1), result.alpha(stage), result.beta(stage), delta, delta/(delta+1));
                    if (obj.options.plotCoarsening && ~isempty(level.g.coord))
                        %figure(1000+stage);
                        figure(obj.figNum); obj.figNum=obj.figNum+1;
                        plot(coarseSet, 'radius', obj.options.radius);
                        %shg; save_figure('png', sprintf('%s_stage%d.png',
                        %level.g.metadata.name, stage));
                        %                        pause;
                    end
                end
            end
            
            % No admissible coarse grid was found
            if (result.numExperiments == 0)
                result = [];
                return;
            else
                % Select the optimal coarsening
                [optimalIndex, T] = result.optimalResult();
                if (obj.logger.debugEnabled)
                    obj.logger.debug('Optimal:%2d   nc = %-5d alpha = %.2f   beta = %.2f\n', ...
                        optimalIndex, size(T,1), result.alpha(optimalIndex), result.beta(optimalIndex));
                end
                %                 if (obj.options.plotCoarsening)
                %                     figure(1100); result.plot('alpha');
                %                     %save_figure('png',
                %                     sprintf('%s_alpha_opt.png',
                %                     %level.g.metadata.name));
                %                 end
            end
        end
        
        function [result, optimalIndex] = nuLoop(obj, level, cycleIndex, nuMin, nuMax, nuDefault, ...
                T, xNuDefault, acfNuDefault, betaNuDefault, coarseSet)
            %----------------------------------------------------------
            % Loop over nu values in nuMin:nuMax except nuDefault.
            %----------------------------------------------------------
            
            % Initializations
            result      = amg.coarse.ResultBundle(level, cycleIndex);
            nu          = [nuDefault-1:-1:nuMin nuDefault:nuMax];
            stage       = 0;
            x0          = xNuDefault;       % Initiates the first direction (going down)
            
            % Break if beta increases twice in a row with increasing nu
            while ((stage < numel(nu)) && ...
                    ((nu(stage+1) <= nuDefault+1) || ...
                    ~result.betaIncreased(stage, obj.options.betaIncreaseTol)))
                stage       = stage + 1;
                currentNu   = nu(stage);
                if (obj.logger.traceEnabled)
                    obj.logger.trace('Nu stage #%d, nu = %2d\n', stage, currentNu);
                end
                if (currentNu == nuDefault)
                    % Going the other direction (up), skip nuDefault (copy
                    % its results from the previous loop) and reset initial
                    % guess.
                    result.addResult(currentNu, T, currentNu, acfNuDefault, betaNuDefault, xNuDefault);
                    %x0 = xNuDefault;
                else
                    % All other nu values, run HCR
                    %[acf, x0]   = obj.measureHcrPerformance(level, currentNu, T, x0);
                    acf = 0;
                    b   = obj.aggregationStrategy.efficiencyMeasure(acf, cycleIndex, coarseSet.coarseningRatio, currentNu);
                    result.addResult(currentNu, T, currentNu, acf, b, x0);
                end
                if (obj.logger.debugEnabled)
                    obj.logger.debug('Stage %2d    nu = %2d   beta = %.2f\n', ...
                        stage, result.parameter(stage), result.beta(stage));
                end
            end
            
            optimalIndex = result.optimalResult();
            if (obj.logger.debugEnabled)
                obj.logger.debug('Optimal:%2d  nu = %2d   beta = %.2f\n', ...
                    optimalIndex, result.parameter(optimalIndex), result.beta(optimalIndex));
            end
            %             if (obj.options.plotCoarsening)
            %                 figure(1101); result.plot('nu');
            %                 %save_figure('png', sprintf('%s_nu_opt.png',
            %                 %level.g.metadata.name));
            %             end
        end
        
        % Not currently in use for caliber-1 P
        %         function [acf, x] = measureHcrPerformance(obj, level, nu,
        %         T, x0)
        %             % Compute HCR statistics. Input: coarse type
        %             operatoer T, cycle % index and initial vector x0 for
        %             HCR run. Returns the HCR ACF % (acf) and the
        %             asymptotic HCR vector x.
        %
        %             % Normalize initial guess to unit norm x0
        %             = x0/(lpnorm(x0)+eps);
        %
        %             % Run HCR hcr             = amg.coarse.Hcr(level, T,
        %             ...
        %                 nu, obj.options.rhsCorrectionFactor, 1);
        %             [acf, details]  = obj.acfComputer.run(level, hcr,
        %             x0);
        %
        %             x = details.asymptoticVector; % Normalize return
        %             value to unit norm as well x               =
        %             x/(lpnorm(x)+eps);
        %         end
    end
end
