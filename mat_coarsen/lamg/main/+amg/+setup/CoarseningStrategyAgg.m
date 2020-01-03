classdef (Hidden, Sealed) CoarseningStrategyAgg < amg.setup.CoarseningStrategy
    %LEVELBUILDER A builder of the finest level.
    %   This class builds the finest level from a Problem object.
    %
    %   See also: MULTILEVELSETUP.
    
    %=========================== PROPERTIES ==============================
    properties (Constant, GetAccess = private)
        myLogger = core.logging.Logger.getInstance('amg.setup.CoarseningStrategyAgg')
        TV_FACTORY = amg.tv.TvFactory
    end
    
    %======================== CONSTRUCTORS ============================
    methods
        function obj = CoarseningStrategyAgg(options)
            % Initialize this object.
            obj = obj@amg.setup.CoarseningStrategy(options);
        end
    end
    
    %======================== IMPL: CoarseningStrategy ================
    methods (Access = protected)        
        function [coarseLevel, hcr, beta, nu, details] = buildInternal(obj, target, problem, fineLevel)
            % Build and return the next-coarser level COARSELEVEL using the
            % strategy encapsulated in this object. FINELEVEL is the
            % coarsest level to date (one above LEVEL).
            
            details = struct('timeCoarsening', 0, 'timeRelax', 0);
            
            % Initialize TVs at the next finer level. Note: using the same
            % initial guess type at all levels
            if (~isempty(obj.options.randomSeed))
                % For reproducible results at all levels
                setRandomSeed(obj.options.randomSeed);
            end
            
            % Test if relaxation is fast; make asymptotic vector TV if slow
            tStart = tic;
            if (~obj.isRelaxationFast(fineLevel))
                coarseLevel     = [];
                hcr             = [];
                beta            = [];
                nu              = [];
                target.state    = amg.setup.CoarseningState.DONE_COARSENING;
                return;
            end
            if (fineLevel.K > 1)
                [tv tv_r] = amg.setup.CoarseningStrategyAgg.TV_FACTORY.generateTvs(...
                    fineLevel, obj.options.tvInitialGuess, fineLevel.K-1, obj.options.tvSweeps, obj.options.lda, obj.options.kpower);
                fineLevel.x = [fineLevel.x tv];
                fineLevel.r = [fineLevel.r tv_r];
            end
            details.timeRelax = details.timeRelax + toc(tStart);
            
            % Create coarse aggregate set
            aggregation = target.aggregator.aggregate(fineLevel, obj.options.cycleIndex);
            if (isempty(aggregation))
                if (obj.myLogger.debugEnabled)
                    obj.myLogger.debug('No coarse grid was found/needed, breaking\n');
                end
                coarseLevel     = [];
                hcr             = [];
                beta            = [];
                nu              = [];
                target.state    = amg.setup.CoarseningState.DONE_COARSENING;
                return;
            end
            [dummy, T, aggregateIndex, beta, nu, hcr] = aggregation.optimalResult(); %#ok
            
            % Initialize the next-coarser level - compute interpolation,
            % Galerkin coarsening and energy correction
            tStart = tic;
            coarseLevel = amg.setup.CoarseningStrategy.LEVEL_FACTORY.newInstance(...
                amg.level.LevelType.AGG, ...
                target.index, ...
                amg.setup.CoarseningState.AGG, ...
                target.relaxFactory, ...
                min(obj.options.tvMax, fineLevel.K + obj.options.tvIncrement), ...
                'name', problem.g.metadata.name, ...
                'fineLevel', fineLevel, 'T', T, 'aggregateIndex', aggregateIndex, ...
                'options', obj.options);
            details.timeCoarsening = details.timeCoarsening + toc(tStart);
            
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
    methods (Access = private)
        function result = isRelaxationFast(obj, level)
            % Estimate relaxation ACF on A*x=0 (in L2 norm - faster to show
            % ACF than energy or residual norms)
            % Level has no 0-degree nodes. Stop if relaxation is fast
            % enough
            if (obj.myLogger.debugEnabled)
                obj.myLogger.debug('Computing relaxation speed\n');
            end
            %             acfComputer = lin.api.AcfComputer(...
            %                 'maxIterations', min(8, 6 + 2*level.index),
            %                 ... 'output', 'full', 'steadyStateTol', 1e-2,
            %                 'sampleSize', 2, ... 'removeZeroModes',
            %                 'mean', ... 'errorNorm', @errorNormL2, ...
            %                 'acfEstimate', 'smooth-filter', 'logLevel',
            %                 1);
            %             [relaxAcf, dummy, x] = acfComputer.run(level,
            %             level.relaxer);
            % Naive estimation of the last nu-initial sweeps
            nu = obj.options.relaxAcfMinSweeps + 2*(level.index-1);
            tvNu = obj.options.tvSweeps;
            initial = 3;                % Discard these many initial iterations from ACF estimate
            if (tvNu < initial)
                error('#TV relaxations < #initial relaxations, case not yet supported');
            end
            x  = 2*rand(level.g.numNodes,1)-1; % must have 0 mean, like any other TV!
            r  = -level.A*x;
            %x = rand(level.g.numNodes,1); % non-0-mean
            %[x, r]  = level.tvRelax(x , r, initial);
            %[tv, rtv] = level.tvRelax(x , r, tvNu-initial);
            %[y, r]  = level.tvRelax(tv, rtv, nu-tvNu); %#ok
            lda = obj.options.lda;
            k = obj.options.kpower;
            n = length(level.A);
            adj = diag(diag(level.A)) - level.A + lda*speye(n);
            d_inv_sqrt = sum(adj, 2).^-0.5;
            d_inv_sqrt(isinf(d_inv_sqrt)|isnan(d_inv_sqrt)) = 0;
            degree = spdiags(d_inv_sqrt, 0, n, n);
            filter = degree*adj*degree;
            y1 = x;
            for i=1:k
                y1 = filter * y1;
            end
            y = y1;
            for i=1:k
                y = filter * y;
            end

            relaxAcf = (norm(y-mean(y))/norm(y1 - mean(y1)))^(1/(nu-initial));
            %relaxAcf = (norm(y-mean(y))/norm(y1 - mean(y1)))^(1/(k));
            
            % Use asymptotic vector of as a TV
            %level.x = tv; %y; % So that TV passes the same # sweeps as all other TVs ==> no need to normalize it differently
            %level.r = rtv; %r;
            level.x = y1; %y; % So that TV passes the same # sweeps as all other TVs ==> no need to normalize it differently
            level.r = -level.A*y1; %r;
            
            if (obj.myLogger.debugEnabled)
                obj.myLogger.debug('Relaxation ACF = %.3f, acceptable ACF = %.3f\n', ...
                    relaxAcf, obj.options.maxCoarseRelaxAcf);
            end
            %aaa = relaxAcf
            %bbb = obj.options.maxCoarseRelaxAcf
            result = (relaxAcf > obj.options.maxCoarseRelaxAcf);
        end
    end
end
