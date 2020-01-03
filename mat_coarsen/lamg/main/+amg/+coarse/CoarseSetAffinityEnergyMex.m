classdef (Hidden, Sealed) CoarseSetAffinityEnergyMex < amg.api.HasOptions
    %COARSESETAFFINITYMEX A coarse aggregate set of a fine-level graph that
    %combines the affinity and energy ratio approaches. Delegates to a MEX
    %file to execute the main loop.
    %   This abstract class is the main data structure used during
    %   aggregation stages. It is the same as CoarseSetAffinityEnergy,
    %   except that it is more modular.
    %
    %   See also: AGGREGATOR.
    
    %=========================== PROPERTIES ==============================
    properties (Constant, GetAccess = private)
        logger = core.logging.Logger.getInstance('amg.coarse.CoarseSetAffinityEnergyMex')
    end
    
    properties (Dependent)
        numNodes            % Fine node set size
        coarseningRatio     % nc/n
    end
    properties (GetAccess = public, SetAccess = private)
        aggregateIndex      % Map of fine node index -> aggregate index = coarse node index
        numAggregates       % Aggregate number counter (nc)
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
        function obj = CoarseSetAffinityEnergyMex(level, dummy1, options) %#ok
            % Initialize this object to the empty coarse aggregate set.
            obj = obj@amg.api.HasOptions(options);
            
            % Initialize TV-related data structures
            n           = level.g.numNodes;
            obj.level   = level;
            obj.x       = level.x;
            obj.x2      = 0.5 * obj.x.^2;
            A           = obj.level.A;
            obj.D       = full(diag(A));
            
            % Prohibit small direct connections from being aggregated
            obj.W       = level.Wstrong;
            degree      = level.g.degree';
            
            if (obj.options.secondDegreeNbhr)
                % Compute limited second-degree neighbor adjacency matrix
                W1          = spones(A);
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
                % Prohibit small second-degree connections from being
                % aggregated
                W2 = filterSmallEntries(W2, max(W2), obj.options.weakEdgeThreshold, 'abs', 'min');
            else
                % Search only first-degree neibhors
                W2          = obj.W;
            end
            
            % Initial affinities
            obj.C       = affinitymatrix(W2, obj.x);
            obj.Cmax    = max(obj.C, [], 1);
            
            % Initialize aggregation data structures
            obj.status              = -ones(1,n); % Mark all nodes as undecided
            obj.aggregateSize       = ones(1,n);
            obj.numAggregates       = n;
            
            % Mark all locally-high-degree nodes as seeds
            t = obj.options.aggregationDegreeThreshold;
            if (t > 0)
                %meanNbhrDegree = medianCol(obj.W, degree);
                meanNbhrDegree = abs(obj.level.g.adjacency)*degree ./ abs(obj.D);
                suns = find(degree >= t*meanNbhrDegree);
                if (obj.logger.debugEnabled)
                    obj.logger.debug('   #suns = %d, marked as seeds\n', numel(suns));
                end
                obj.status(degree >= t*meanNbhrDegree) = 0;
            end
            
            % Aggregate all loose nodes (with no strong connections, where
            % relaxation is fast) to a single dummy aggregate to keep
            % coarse matrix zero-row sum, at the slight expense of
            % unnecessarily interpolating to these points
            loose = find(~max(W2,[],1));
            if (obj.options.aggregateLooseNodes)
                obj.aggregateAll(loose); %#ok
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
            
            % Relax energy ratio (needs to be done only locally, for nodes
            % with weak algebraic connections to all neighbors)
            %            if (stage < 3)
            ratioMax = options.ratioMax;
            %            else
            %                ratioMax = 10;
            %            end
        end
        
        function aggregationStage(obj, delta, ratioMax) %#ok
            % Purpose: further aggregate the curent coarse aggregate set
            % defined by status, using an affinity strength threshold
            % DELTA.
            
            %------------------------------------------------------
            % Compute delta-affiliates matrix N
            %------------------------------------------------------
            % Update affinities every stage -- avoided due to extra work
            % even though this could improve the aggregation
            %obj.C       = affinityMatrix(obj.W, obj.level.x); Cmax1 =
            %diag(max(obj.C, [], 1))*spones(obj.C); obj.Cmax    =
            %max(Cmax1, Cmax1');
            
            % Relative threshold
            N = obj.C;
%            N = filterSmallEntries(obj.C, obj.Cmax, delta, 'value', 'max');
%             c = obj.C ./ (1 - obj.C);
%             cmax = obj.Cmax ./ (1 - obj.Cmax);
%             N = filterSmallEntries(c, cmax, delta, 'value', 'max');

            % Absolute threshold 
%             n       = obj.numNodes;
%             [i,j,c] = find(obj.C);
%             k       = find(c >= delta); % delta/(1+delta);
%             N       = sparse(i(k), j(k), c(k), n, n, nzmax(obj.C));
            
            if (obj.logger.debugEnabled)
                obj.logger.debug('   #delta-affiliate edges = %d / %d total edges\n', ...
                    nnz(N)/2, nnz(obj.C)/2);
            end
            
            %------------------------------------------------------
            % Find undecided nodes = nodes with open N-neighbors
            %------------------------------------------------------
            stat        = obj.status;
            isOpen      = stat <= 0;         % Open = non-associates = seeds or undecided
            undecided   = find(stat < 0);    % Undecided
            bins        = undecidedNodes(N, undecided, isOpen, 10);
            if (isempty(bins))
                if (obj.logger.infoEnabled)
                    obj.logger.info('No undecided nodes\n');
                end
                return;
            end
            
            %------------------------------------------------------
            % Aggregation sweep over undecided nodes
            %------------------------------------------------------
            [obj.x, obj.x2, obj.status, obj.aggregateSize, numAggregatesNew] = ...
                aggregationsweep(bins, ...
                obj.x, obj.x2, stat, obj.aggregateSize, uint32(obj.numAggregates), ...
                N, obj.D, obj.W, ...
                ratioMax, ...
                obj.options.coarseningWorkGuard/obj.options.cycleIndex);
            obj.numAggregates = double(numAggregatesNew);
            
            % Aggregate all nodes that only depend on coarse aggregates
            % into a single dummy aggregate. No interpolation is needed,
            % since their values are exactly determined by aggregate
            % values.
            % Hmm -- leads to large two-level cycle ACF since the
            % -cumulative- effect of independent node edges affects the
            % coarse-level approximation of smooth components.
%             if (0) %((delta < 0.6) && (obj.numAggregates >= 0.7 * obj.level.g.numNodes))
%                 stat = obj.status;
%                 independent = independentUndecided(obj.level.A, find(stat < 0), stat);
%                 obj.aggregateAll(independent);
%             end
        end % aggregationStage()
    end
    
    methods (Sealed)
        function T = typeOperator(obj, varargin)
            % Convert aggregate data into a sparse matrix T so that x^c =
            % T*x is the coarse counterpart of a fine-level vector x.
            % OBJ.TYPEOPERATOR('NO-SCALE') returns the non-row-sum-scaled
            % version of T.
            
            % Create a map of i -> aggregateIndex
            i   = obj.computeAggregateIndex();
            n   = numel(i);
            nc  = obj.numAggregates;
            T   = sparse(i, 1:n, ones(1,n), nc, n);
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
        function detachNode(obj, i)
            % Remove node i from its aggregate. Useful for debugging. i can
            % be a vector.
            if (obj.status(i) > 0)
                obj.status(i) = 0; % Make i its own seed
                obj.numAggregates = obj.numAggregates+1;
            end
        end
        
        function i = computeAggregateIndex(obj)
            % Create a map of node index -> aggregate index
            stat = obj.status();
            stat(stat < 0) = 0;             % Convert all undecided seeds to their own aggregates
            seeds = find(stat == 0);
            stat(seeds) = seeds;
            
            aggregateIndexFine        = zeros(1, obj.numNodes);
            aggregateIndexFine(seeds) = 1:numel(seeds);
            % Create a map of i -> aggregateIndex
            obj.aggregateIndex = aggregateIndexFine(stat);
            i = obj.aggregateIndex;
        end
        
        function aggregateAll(obj, nodes)
            % Aggregate the set of NODES into a single coarse aggregate.
            if (~isempty(nodes))
                looseSeed               = nodes(1); % Any loose node would work
                obj.status(nodes)       = looseSeed;
                obj.status(looseSeed)   = 0;
                obj.numAggregates       = obj.numAggregates - numel(nodes) + 1;
                if (obj.logger.debugEnabled)
                    obj.logger.debug('   %d nodes aggregated to a single node, seed #%d\n', numel(nodes), looseSeed);
                end
            end
        end
    end
end