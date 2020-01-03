classdef (Hidden, Sealed) CoarseSetAffinityEnergy < amg.api.HasOptions
    %COARSESET A coarse aggregate set of a fine-level graph that combines
    %the affinity and energy ratio approaches.
    %   This abstract class is the main data structure used during
    %   aggregation stages. It is the same as CoarseSetAffinityEnergy,
    %   except that it is more modular.
    %
    %   See also: AGGREGATOR.
    
    %=========================== PROPERTIES ==============================
    properties (Constant, GetAccess = private)
        logger = core.logging.Logger.getInstance('amg.coarse.CoarseSetAffinityEnergy')
    end
    
    properties (Dependent)
        numNodes            % Fine node set size
        coarseningRatio     % nc/n
        %aggregateIndex      % Map of fine node index -> aggregate index =
        %coarse node index
    end
    properties (GetAccess = public, SetAccess = private)
        numAggregates       % Aggregate number counter (nc)
        aggregateIndex      % Not in use
    end
    properties (GetAccess = private, SetAccess = private)
        level               % Original fine level
        x                   % X (nc x K) = TV matrix (each column is a TV); A working copy updated upon each node aggregation.
        x2                  % 0.5 * x.^2
        W                   % Fine-level adjacency matrix
        D                   % Mass matrix (sum(W))
        C                   % Affinity matrix
        Cmax                % Cmax_{ij} = max{cii,cjj}
        status              % An array holding the status of each node during aggregation: undecided (status=-1), seed (status=0) or associate (status=seed index >= 1)
        aggregateSize       % aggregateSize(i) = the size of aggregrate to which i belongs. For undecided nodes, aggregateSize=1
        colors              % Cached aggregate plot colors
    end
    
    %======================== CONSTRUCTORS ============================
    methods
        function obj = CoarseSetAffinityEnergy(level, dummy1, options) %#ok
            % Initialize this object to the empty coarse aggregate set.
            obj = obj@amg.api.HasOptions(options);
            
            % Initialize TV-related data structures
            n           = level.g.numNodes;
            obj.level   = level;
            obj.x       = level.x;
            obj.x2      = 0.5 * obj.x.^2;
            obj.W       = level.g.adjacency;
            degree      = level.g.degree;
            %meanDegree  = median(degree); % Or some representative mean degree
            
            if (obj.options.secondDegreeNbhr)
                % Compute limited second-degree neighbor adjacency matrix
                W1          = spones(level.A);
                % 2nd degree nbhr matrix = remove lowDegree rows from W1;
                % -> save both 1st, 2nd degree nbhrs in W2
                t           = obj.options.secondDegreeNbhrThreshold;
                W2          = W1;
                if (t > 0)
                    meanDegree  = median(degree); % Or some representative mean degree
                    W2(:,degree > t*meanDegree) = 0;
                end
                W2          = W2';
                W2          = W2*W1;
                % Remove diagonal elements
                [i,j]       = find(W2);
                k           = (j ~= i);
                w2Size      = numel(find(k));
                W2          = sparse(i(k), j(k), ones(w2Size,1), n, n, w2Size);
                % Symmetrize
                W2          = max(W2,W2');
            else
                % Search only first-degree neibhors
                W2          = obj.W;
            end
            % Prohibit small direct connections from being aggregated
            W2 = filterSmallEntries(W2, max(W2), obj.options.weakEdgeThreshold, 'abs', 'min');
            
            obj.D       = full(diag(level.A));
            % Initial affinities
            obj.C       = affinitymatrix(W2, obj.x);
            Cmax1       = diag(max(obj.C, [], 1))*spones(obj.C);
            obj.Cmax    = max(Cmax1, Cmax1');
            
            % Initialize aggregation data structures
            obj.status              = -ones(1,n); % Mark all nodes as undecided
            obj.aggregateSize       = ones(1,n);
            obj.numAggregates       = n;
            
            % Mark all high-degree nodes as seeds
            t = obj.options.aggregationDegreeThreshold;
            if (t > 0)
                meanNbhrDegree = medianCol(obj.W, degree);
                obj.status(degree >= t*meanNbhrDegree) = 0;
            end
            
            % Aggregate all loose nodes (with no strong connections, where
            % relaxation is fast) to a dummy aggregate to keep coarse
            % matrix zero-row sum, at the slight expense of unnecessarily
            % interpolating to these points
            loose                   = find(~max(W2,[],1));
            if (~isempty(loose))
                looseSeed               = loose(1); % Any loose node would work
                obj.status(loose)       = looseSeed;
                obj.status(looseSeed)   = 0;
                obj.numAggregates       = obj.numAggregates - numel(loose) + 1;
            end
            
            % Prepare aggregate plot colors; undecided node color = white
            obj.colors = [rand(obj.numNodes, 3); [1 1 1]];
        end
    end
    
    %======================== METHODS =================================
    methods
        function [d, ratioMax] = delta(obj, stage, options) %#ok<MANU>
            % Returns the delta-parameter growth model (function handle).
            %d = options.deltaInitial * options.deltaDecrement.^(stage-1);
            %d = options.deltaInitial - options.deltaDecrement*(stage-1);
            d = amg.coarse.deltaModel(stage, options);
            ratioMax = options.ratioMax;
        end
        
        function aggregationStage(obj, delta, ratioMax)
            % Purpose: further aggregate the curent coarse aggregate set
            % defined by status, using an affinity strength threshold
            % DELTA.
            
            %------------------------------------------------------
            % Compute delta-affiliates matrix N
            %------------------------------------------------------
            % Update affinities every stage -- avoided due to extra work
            % even though this could improve the aggregation
            %obj.C       = affinityMatrix(obj.W, obj.level.x); Cmax1
            %= diag(max(obj.C, [], 1))*spones(obj.C); obj.Cmax    =
            %max(Cmax1, Cmax1');
            n       = obj.numNodes;
            [i,j,c] = find(obj.C);
            %cmax    = nonzeros(obj.Cmax);
            %k       = find(c >= delta*cmax);       % Relative threshold
            k       = find(c >= delta);             % Absolute threshold
            %k       = find(c >= delta/(1+delta));
            N       = sparse(i(k), j(k), c(k), n, n, nzmax(obj.C));
            if (obj.logger.debugEnabled)
                obj.logger.debug('#delta-affiliate edges = %d / %d total edges\n', ...
                    nnz(N)/2, numel(c)/2);
            end
            
            %------------------------------------------------------
            % Identify undecided nodes with N-neighbors
            %------------------------------------------------------
            stat            = obj.status;
            undecided       = find(stat < 0);
            undecided       = undecided(sum(spones(N(:,undecided))) > 0);
            if (isempty(undecided))
                if (obj.logger.infoEnabled)
                    obj.logger.info('No undecided nodes\n');
                end
                return;
            end
            
            % Sort undecided nodes by descending priority = max affinity to
            % an "open" (non-aggregated) node so that stronger connections
            % are hopefully aggregated before weaker
            open    = stat <= 0;
            cm      = max(obj.C(undecided,open), [], 2);
            bins    = cellfun(@(x)(undecided(x)), binsort(cm, 10), 'UniformOutput', false);
            
            %------------------------------------------------------
            % Aggregation sweep over undecided nodes
            %------------------------------------------------------
            [obj.x, obj.x2, obj.status, obj.aggregateSize, obj.numAggregates] = ...
                aggregationSweep_matlab(bins, ...
                obj.x, obj.x2, stat, obj.aggregateSize, obj.numAggregates, N, obj.D, obj.W, ...
                ratioMax, obj.options.coarseningWorkGuard/obj.options.cycleIndex);
        end % aggregationStage()
    end
    
    methods (Sealed)
        function T = typeOperator(obj, varargin)
            % Convert aggregate data into a sparse matrix T so that x^c =
            % T*x is the coarse counterpart of a fine-level vector x.
            % OBJ.TYPEOPERATOR('NO-SCALE') returns the non-row-sum-scaled
            % version of T.
            
            % Create a map of i -> aggregateIndex
            a = obj.computeAggregateIndex();
            n   = numel(a);
            nc  = obj.numAggregates;
            T   = sparse(a, 1:n, ones(1,n), nc, n);
            % Scale T to unit row-sums, so that the coarse system
            % represents a [zero-sum] graph Laplacian
            if ((numel(varargin) < 1) || ~strcmp('no-scale', varargin{1}))
                T = (diag(sum(T,2))) \ T;
            end
        end
        
        function plot(obj, varargin)
            % Plot the coarse set aggregates and their connections
            defaultOpts = struct('label', 1:obj.numNodes);
            opts = optionsOverride(defaultOpts, struct(varargin{:}));
            plotter = graph.plotter.GraphPlotter(obj.level.g, opts);
            
            s = obj.status;
            s(s == 0) = find(s == 0);
            s(s < 0) = obj.numNodes+1;
            c = obj.colors(s,:);
            
            plotter.plotNodes('FaceColors', c, 'textColor', 'k', 'EdgeColor', 'k', ...
                'label', opts.label);
            plotter.plotEdges('LineWidth', 1);
        end
    end
    
    %======================== GET & SET ===============================
    methods
        function numNodes = get.numNodes(obj)
            % Return the coarse set size.
            numNodes = obj.level.g.numNodes;
        end
        
        function coarseningRatio = get.coarseningRatio(obj)
            % nc/n
            coarseningRatio = (1.0*obj.numAggregates)/obj.numNodes;
        end
    end
    
    %======================== PRIVATE METHODS =========================
    methods (Access = private)
        function aggregateIndex = computeAggregateIndex(obj)
            % Create a map of node index -> aggregate index
            
            % Create a map of seed -> aggregateIndex
            stat = obj.status();
            stat(stat < 0) = 0;             % Convert all undecided seeds to their own aggregates
            seeds = find(stat == 0);
            stat(seeds) = seeds;
            
            aggregateIndexFine        = zeros(1, obj.numNodes);
            aggregateIndexFine(seeds) = 1:numel(seeds);
            % Create a map of i -> aggregateIndex
            aggregateIndex = aggregateIndexFine(stat);
        end
        
        function detachNode(obj, i)
            % Remove node i from its aggregate. Useful for debugging. i can
            % be a vector.
            if (obj.status(i) > 0)
                obj.status(i) = 0; % Make i its own seed
                obj.numAggregates = obj.numAggregates+1;
            end
        end
    end
end