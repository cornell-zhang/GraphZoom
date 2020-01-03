classdef (Hidden, Sealed) CoarseSetLocalRelax < amg.coarse.CoarseSet
    %COARSESET A coarse aggregate set of a fine-level graph.
    % Local relaxation on TVs at each considered associate i; TV values are
    % restored to their original values after i's decision. Affinities are
    % computed on-the-fly.
    %
    %   @DEPRECATED
    %   See also: AGGREGATOR, COARSESET.
    
    %=========================== PROPERTIES ==============================
    properties (Constant, GetAccess = private)
        myLogger = core.logging.Logger.getInstance('amg.coarse.CoarseSetLocalRelax')
    end
    
    %======================== CONSTRUCTORS ============================
    methods
        function obj = CoarseSetLocalRelax(level, associateHolder, options)
            % Initialize this object to the empty coarse aggregate set.
            obj = obj@amg.coarse.CoarseSet(level, associateHolder, options);
        end
    end
    
    %======================== IMPL: CoarseSet =========================
    methods (Access = protected)
        function s = bestSeedInternal(obj, i, delta)
            % Purpose: return the an aggregate seed s to associate a node i
            % with. Input:
            %     i = associate node delta = affinity strength threshold
            % Output: seed node index s to associate i with, or 0, if no
            % such node is found. Find all strong affinities
            
            % Find J = set of all i's neighboring seeds
            j   = find(obj.level.A(:,i))';
            j(~obj.isSeed(j) | (j == i)) = [];
            
            % Compute updated affinities between i and J. X(i) is already
            % set to the aggregate value by preUpdate() if i is an
            % aggregate
            c   = obj.affinityComputer(obj.x(i,:), obj.x(j,:));
            
            % Find strongly-affinitive neighbor s s.t. C(i,s) >= delta, or
            % 0 if such a neighbor does not exist.
            
            c(c < delta) = 0;
            if (isempty(c) || (max(c) == 0))
                s = 0;
            else
                % Introduce a slight favoritism towards smaller aggregates
                % Seems to be even worse - forms staggered aggregates with
                % large energy discrepancy
                alphaJ  = obj.aggregateSize(j);
                alphaI  = obj.aggregateSize(i);
                e       = 0.1*(1-delta);
                [dummy, k]  = max(c ./ (1-e + e*(alphaI + alphaJ - 1))); %#ok
                s       = j(k(1));
            end
            if (i == obj.options.coarseningDebugEdgeIndex)
                obj.myLogger.trace('bestSeed() c =');
                disp([j' c]);
                disp(s);
                aaa=0; %#ok
            end
            %fprintf('i=%d  best seed s=%d\n', i, s);
        end
        
        function preVisit(obj, i)
            % Purpose: update affinities among nodes upon aggregation.
            % Perform local compatible relaxation sweeps.
            %
            % Input: i = node to be aggregated with the seed s. Must be a
            % seed of an existing aggregate. s = seed to aggregate i into
            
            % Find all neighbors of i
            [Ai, dummy] = find(obj.level.A(:,i)); %#ok
            %[Ai, dummy] = find(obj.level.A(:,Ai)); % Add 2nd-degree neighbors
            
            % Find their seeds
            seeds   = unique(obj.seed(Ai));
            
            % Find j = all associates of these seeds Prepare nz list for
            % compatibility operator T
            sz      = obj.aggregateSize(seeds);
            Nj      = sum(sz);
            j       = zeros(1,Nj);
            s       = zeros(1,Nj);
            Tsj     = zeros(Nj,1);
            index   = 0;
            k       = 0;
            for seed = seeds
                k           = k+1;
                Tseed       = obj.associates(seed).list;
                Nseed       = numel(Tseed);
                range       = index+1:index+Nseed;
                j(range)    = Tseed;
                s(range)    = seed;
                Tsj(range)  = 1.0;
                index       = index + Nseed;
            end
            % Create compatibility operator
            T = sparse(j, s, ones(size(s)), obj.numNodes, obj.numNodes);
            T = T(j,j);
            T = T*T';
            T = (diag(sum(T,2))) \ T;
            
            % Set up the local relaxation system
            Ajj = obj.level.A(j,j);
            y   = obj.x(j,:);
            b   = Ajj*y - obj.level.r(j,:);
            M   = tril(Ajj);
            N   = Ajj - M;
            
            % Perform local habitual compatible relaxation sweeps (that set
            % the aggregates to their -current- value, not 0)
            for sweep = 1:obj.options.tvNumLocalSweeps
                % Local relaxation on the j points
                y = M\(b - N*y);
                % Average TVs over aggregates
                y = T*y;
                %                 for seed = seeds
                %                     Tseed =
                %                     obj.associateHolder.associates(seed).
                %                     list; obj.x(Tseed,:) =
                %                     repmat(mean(obj.x(Tseed,:),1),
                %                     numel(Tseed), 1);
                %                 end
            end
            if (i == obj.options.coarseningDebugEdgeIndex)
                aaa=0; %#ok
            end
            obj.x(j,:) = y;
        end
        
        function postVisit(obj, i, dummy) %#ok
            % Purpose: update affinities among nodes upon aggregation.
            % Input: i = node to be aggregated with the seed s. Must be a
            % seed of an existing aggregate. s = seed to aggregate i into
            
            % Restore local TVs to their state before obj.preUpdate(i)
            j           = find(obj.level.A(:,i));
            obj.x(j,:)  = obj.level.x(j,:);
        end
        
        function postUpdate(obj, i, s) %#ok
            % Purpose: update affinities among nodes upon aggregation.
            % Input: i = node to be aggregated with the seed s. Must be a
            % seed of an existing aggregate. s = seed to aggregate i into
        end
    end
    
    %======================== PRIVATE METHODS =========================
    methods (Access = private)
    end
end