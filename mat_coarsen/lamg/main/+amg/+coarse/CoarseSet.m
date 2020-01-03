classdef CoarseSet < amg.api.HasOptions
    %COARSESET A coarse aggregate set of a fine-level graph.
    %   This abstract class is the main data structure used during
    %   aggregation stages.
    %
    %   See also: AGGREGATOR.
    
    %=========================== PROPERTIES ==============================
    properties (Constant, GetAccess = private)
        logger = core.logging.Logger.getInstance('amg.coarse.CoarseSet')
    end
    
    properties (Dependent)
        numNodes            % Fine node set size
        aggregateIndex      % Map of fine node index -> aggregate index = coarse node index
        coarseningRatio     % nc/n
    end
    properties (GetAccess = public, SetAccess = protected)
        numAggregates       % Aggregate number counter (nc)
        isSeed              % Return a boolean array indicating whether each node is a seed.
    end
    properties (GetAccess = protected, SetAccess = private)  % Internal data structures
        level               % Original fine level reference
        %W                   % Fine-level adjacency matrix reference. Contains STRONG CONNECTIONS only
        affinityComputer    % Affinity computation strategy - used when updating affinities
        subtractMean        % Copied from options, for faster access in internal loops
    end
    properties (GetAccess = protected, SetAccess = protected)  % Internal data structures
        x                   % X (nc x K) = TV matrix (each column is a TV); A working copy that is updated upon each node aggregation.
        associates          % A struct array of size n. associates(i).list holds the list of immediate associates of seed i's aggregates.
        seed                % Index array. seed(i) is the fine-level node index of the aggregate seed with which i is associated.
        aggregateSize       % Array that maps seed index to aggregate size. If i is not a seed, aggregateSize(i) is 0.
    end
    properties (GetAccess = private, SetAccess = private)  % Internal data structures
        colors              % Random colors for plots (computed and cached upon object construction)
        data                % data{i} holds the associates' data of node i
    end
    
    %======================== CONSTRUCTORS ============================
    methods
        function obj = CoarseSet(level, associateHolder, options)
            % Initialize this object to the empty coarse aggregate set.
            obj = obj@amg.api.HasOptions(options);
            obj.subtractMean = options.subtractMean;
            
            % initialize node data structures
            n                       = level.size;
            obj.level               = level;
%             obj.W                   = filterSmallEntries(...
%                 obj.level.A - diag(diag(obj.level.A)), ...
%                 obj.options.minAffinity);
            %            obj.W = obj.level.g.adjacency;
            
            % Initialize node associates data structure for n nodes. Each
            % node is its own aggregate
            obj.numAggregates   = associateHolder.numAggregates;
            obj.seed            = associateHolder.seed;
            nonEmptySet         = (obj.numAggregates ~= obj.numNodes);
            obj.associates      = associateHolder.associates; % Initial allocation for associate list of each aggregate
            if (nonEmptySet)
                obj.aggregateSize   = [];
                obj.isSeed          = (obj.seed == (1:obj.numNodes));
            else
                obj.aggregateSize   = ones(n,1);
                obj.isSeed          = true(1,n);
            end
            
            % Initialize TVs
            obj.x                   = level.x;
            % For plots
            obj.colors              = rand(n,3);
            
            if (~associateHolder.fixedPattern)
                % Compute initial node affinities between direct graph
                % neighbors. Since MATLAB uses compressed-column format,
                % access columns and convert them to C-rows
                obj.affinityComputer = @amg.coarse.affinity_l2_optimized;
            end
        end
    end
    
    %======================== METHODS =================================
    methods
        function d = delta(obj, stage, options) %#ok<MANU>
            % Returns the delta-parameter growth model (function handle).
            d = amg.coarse.deltaModel(stage, options);
        end
    end
    
    methods (Sealed)
        function s = bestSeed(obj, i, delta)
            % Purpose: return the an aggregate seed s to associate a node i
            % with. Input:
            %     i = associate node delta = affinity strength threshold
            % Output: seed node index s to associate i with, or 0, if no
            % such node is found. Find all strong affinities
            obj.preVisit(i);
            [s, obj.x] = obj.bestSeedInternal(i, delta, obj.x);
            obj.postVisit(i);
        end
        
        function addNodeToAggregate(obj, i, s)
            % Add node i to an the aggregate seeded at s.
            
            % Update associates Append the list to s's associates and set
            % its seed to s. Note: these lists are disjoint, so we don't
            % need a set union
            obj.numAggregates    = obj.numAggregates - 1;
            Ti                   = obj.associates(i).list;
            Ni                   = numel(Ti);
            Ns                   = numel(obj.associates(s).list);
            obj.associates(s).list(Ns+1:Ns+Ni)  = Ti;
            obj.seed(Ti)         = s;
            obj.isSeed(Ti)       = false;
            obj.aggregateSize(s) = obj.aggregateSize(s)+1;
            
            % Update TVs and affinities after i decision
            obj.postUpdate(i, s);
        end
        
        function T = typeOperator(obj, varargin)
            % Convert aggregate data into a sparse matrix T so that x^c =
            % T*x is the coarse counterpart of a fine-level vector x.
            % OBJ.TYPEOPERATOR('NO-SCALE') returns the non-row-sum-scaled
            % version of T.
            
            % Create a map of i -> aggregateIndex
            aggregateIndex = obj.aggregateIndex();
            n   = numel(aggregateIndex);
            nc  = obj.numAggregates;
            T   = sparse(aggregateIndex, 1:n, ones(1,n), nc, n);
            % Scale T to unit row-sums, so that the coarse system
            % represents a [zero-sum] graph Laplacian
            if ((numel(varargin) < 1) || ~strcmp('no-scale', varargin{1}))
                T = (diag(sum(T,2))) \ T;
            end
        end
        
        function detachNode(obj, i)
            % Remove node i from its aggregate. Useful for debugging.
            if (~obj.isSeed(i))
                obj.numAggregates    = obj.numAggregates + 1;
                Ti                   = obj.associates(i).list;
                Ni                   = numel(Ti);
                %fprintf('i=%d  Ni=%d\n', i, Ni);
                s                    = obj.seed(i);
                obj.associates(s).list = setdiff(obj.associates(s).list, Ti);
                obj.seed(Ti)         = i;
                obj.isSeed(i)        = true;
                obj.aggregateSize(s) = obj.aggregateSize(s)-Ni;
            end
        end
        
        function plot(obj, varargin)
            % Plot the coarse set aggregates and their connections
            defaultOpts = struct('label', []);
            opts = optionsOverride(defaultOpts, struct(varargin{:}));
            plotter = graph.plotter.GraphPlotter(obj.level.g, opts);
            
            % Prepare aggregate colors; lone seeds color = black
            %c           = colors(obj.associateHolder.aggregateIndex,:);
            c           = obj.colors(obj.associateHolder.seed,:);
            
            loneSeeds = obj.isSeed & (obj.associateHolder.aggregateSize == 1);
            numLoneSeeds = numel(find(loneSeeds));
            %c(loneSeeds,:) = repmat([0 0 0], [numLoneSeeds 1]);
            c(loneSeeds,:) = repmat([1 1 1], [numLoneSeeds 1]);
            
            plotter.plotNodes('FaceColors', c, 'textColor', 'k', 'EdgeColor', 'k', ...
                'label', opts.label);
            plotter.plotEdges('LineWidth', 1);
        end
    end
    
    methods
        function addTv(obj, T, xNew)
            % Add a test vector to this object's TV list.
            
            if (lpnorm(xNew) < eps)
                % Do not add a zero vector
                return;
            end
            
            % Add fine-level x to level TV set
            obj.level.addTv(xNew);
            
            % Aggregate x so that its values are comparable with all other
            % TVs at this stage, and append it to our TV set (which is
            % different than level.x)
            xNew(obj.isSeed)        = T*xNew;
            obj.x                   = [obj.x xNew];
            obj.postAddTv(xNew); % sub-class hook
        end       
    end
    
    %======================== GET & SET ===============================
    methods
        function numNodes = get.numNodes(obj)
            % Return the coarse set size.
            numNodes = obj.level.size;
        end
        
        function aggregateIndex = get.aggregateIndex(obj)
            % Create a map of node index -> aggregate index
            
            % Create a map of seed -> aggregateIndex
            nc                              = obj.numAggregates;
            aggregateIndexFine              = zeros(1, obj.numNodes);
            aggregateIndexFine(obj.isSeed)  = 1:nc;
            % Create a map of i -> aggregateIndex
            aggregateIndex = aggregateIndexFine(obj.seed);
        end
        
        function coarseningRatio = get.coarseningRatio(obj)
            % nc/n
            coarseningRatio = (1.0*obj.numAggregates)/obj.numNodes;
        end
    end
    
    %======================== PRIVATE METHODS =========================
    methods (Access = protected, Abstract)
        s = bestSeedInternal(obj, i, delta)
        % Purpose: return the an aggregate seed s to associate a node i
        % with. Input:
        %     i = associate node delta = affinity strength threshold
        % Output: seed node index s to associate i with, or 0, if no such
        % node is found. Find all strong affinities
    end
    
    methods (Access = protected)
        function preVisit(obj, i) %#ok
            % Purpose: update TVs at the beginning of visiting node i.
        end
        
        function postVisit(obj, i) %#ok
            % Purpose: update TVs at the end of visiting node i.
        end
        
        function postUpdate(obj, i, s) %#ok
            % Purpose: update TVs and affinities right after node i's
            % aggregation with s. A hook. Input: i = node to be aggregated
            % with the seed s. Must be a seed of an existing aggregate. s =
            % seed to aggregate i into
        end
     
        function postAddTv(obj, xnew) %#ok
            % Runs at the end of addTv(). A sub-class hook.
        end
   
    end
end