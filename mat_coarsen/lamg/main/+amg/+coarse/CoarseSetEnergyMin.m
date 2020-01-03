classdef (Hidden, Sealed) CoarseSetEnergyMin < amg.coarse.CoarseSet
    %COARSESET A coarse aggregate set of a fine-level graph -
    %energy-minimization-based.
    %   This class is the main data structure used during aggregation
    %   stages.
    %
    %   See also: AGGREGATORHCR.
    
    %=========================== PROPERTIES ==============================
    properties (Constant, GetAccess = private)
        myLogger = core.logging.Logger.getInstance('amg.coarse.CoarseSetEnergyMin')
    end
    
    properties (GetAccess = private, SetAccess = private)
        numPrintoutLines = 10   % Resolution of progress bar
        meanDegree              % Mean/median node degree in A
        D                       % diag(A)
        W                       % Weighted adjacency matrix
        C                       % C (nc x nc) = sparse affinity matrix in compressed row format. This is a cell array of row data. row i holds an array of [j, aij], sorted by descending aij (aij assumed to be positive)
    end
    
    %======================== CONSTRUCTORS ============================
    methods
        function obj = CoarseSetEnergyMin(level, associateHolder, options)
            % Initialize this object to the empty coarse aggregate set.
            obj = obj@amg.coarse.CoarseSet(level, associateHolder, options);
            
            % An O(n)-computable approximation to the median would also
            % work
            obj.meanDegree  = median(obj.level.g.degree);
            obj.D           = full(diag(obj.level.A));
            obj.W           = obj.level.g.adjacency;
            obj.C           = obj.initNbhrLists(obj.W);
        end
    end
    
    %======================== IMPL: CoarseSet =========================
    methods
        function addTv(obj, dummy1, dummy2) %#ok
            % Does not support adding a test vector to this object's TV
            % list.
        end
        
        function aggregationStage(obj, delta)
            % Purpose: further aggregate the coarse aggregate set defined
            % by seed, using an affinity strength threshold delta Input:
            %      coarseSet = coare set object - passed by reference delta
            %      = affinity strength threshold numSweepsPerAggregation =
            %      number of association-attempt sweeps to perform over
            %      coarse set nodes
            %Output: upon return from this method, coarseSet is updated
            %with the new set of aggregates.
            
            % Initializations, aliases
            n               = obj.numNodes;
            visited         = false(1, n);  % visited(i) = was seed i visited during the association sweep or not
            [lam, dummy1, dummy2, x, aggregateSize, associates, r, q] = obj.initArrays(); %#ok
            cMin            = delta/(1+delta);
            nodes           = obj.initSeedsArray();
            subtractMean    = obj.subtractMean;
            nCols           = size(x,2);
            cols            = ones(nCols,1);
            
            for i = nodes                   % Note: make sure the seeds array is copied by value to a working copy before this loop, because it changes during the loop
                if (visited(i))
                    continue;
                end
%                 if (obj.myLogger.debugEnabled)
%                     obj.myLogger.debug('Visiting i=%d\n', i);
%                 end
                % seed i hasn't yet been visited during this sweep, visit
                % it and set its flag to visited
                visited(i) = true;
                
                %=====================================================
                % Find an aggregate seed s to associate i with
                %=====================================================
                
                %------------------------------------------------
                % Filter 2: Find i's seed neighbors
                %------------------------------------------------
                Ci      = obj.C(i).index;
                index   = Ci(obj.isSeed(Ci));
                if (isempty(index))
                    continue;
                end
                
                %------------------------------------------------
                % Filter 3: Compute affinities and consider only strongly
                % affinitive neighbors
                %------------------------------------------------
                c = obj.computeAffinities(x, i, index, subtractMean);
                j = find(c >= cMin);
                if (isempty(j))
                    continue;
                end
                index = index(j);
                
                %------------------------------------------------
                % Filter 4: find the neighbor s that minimizes the worst
                % energy ratio among all TVs. If it has an acceptable
                % energy ratio, aggregate i with s.
                %------------------------------------------------
                [X, Ec, E] = computeEnergies(obj, x, D, r, q, i, index); %#ok
                
                % Find the neighbor that minimizes G = [F + lam*aggregate
                % size], where F = worst energy ratio over all TVs.
                % Aggregate if F is small enough (-not- G).
                F        = max(Ec./E, [], 2);
                G        = F + lam * aggregateSize(index);
                [dummy, k]   = min(G); %#ok
                minRatio = F(k);
                if (minRatio > obj.options.ratioMax)
                    continue;
                end
                
                %------------------------------------------------
                % There exists an affinitive neighbor s to associate i
                % with, aggregate
                %------------------------------------------------
                s           = index(k(1));
                xAggregate  = X(1,:);
                
                % Update s's associate list (Ts)
                obj.numAggregates = obj.numAggregates - 1;
                [associates, aggregateSize] = obj.updateAssociateLists(i, s, associates, aggregateSize);
                updateNbhrLists(obj, i, s);
                
                % Update energy terms
                Ts          = associates(s).list;
                [r, q]      = obj.updateEnergyTerms(r, q, W, x, cols, Ts, xAggregate); %#ok

                % Effect TV value on new aggregate
                xAggregate  = xAggregate(ones(numel(Ts),1),:);
                x(Ts,:)     = xAggregate;
                
                % Debugging: these norms must be 0 (updating energy terms
                % vs. explicitly computing them. Note: updates cause
                % round-off accmulation. May need to compute energy terms
                % directly once in a while).
                %[norm(r - W*x) norm(q - W * (0.5*x.^2))]
                
                visited(s) = true;                % Prevent visiting the seed again during this sweep
                % Debugging printouts
%                 if (obj.myLogger.debugEnabled)
%                     obj.myLogger.debug('Aggregating i=%d with s=%d\n', i, s);
%                 end
                if (i == s)
                    error('best seed = i for i=%d - this can never happen!!!\n', i);
                end
            end
            
            % Restore local arrays that were changed during the main loop
            % above into object fields. All for MATLAB speed -- very ugly
            % and not needed in a general OO implementation
            obj.x = x;
            obj.aggregateSize = aggregateSize;
            obj.associates = associates;
        end
    end
    
    %======================== PRIVATE METHODS =========================
    methods (Access = protected)
        function s = bestSeedInternal(obj, dummy1, dummy2) %#ok
            % Purpose: return the an aggregate seed s to associate a node i
            % with. Input:
            %     i = associate node delta = affinity strength threshold
            % Output: seed node index s to associate i with, or 0, if no
            % such node is found. Find all strong affinities
            s = [];
        end
    end
    
    methods (Access = private)
        function [lam, D, W, x, aggregateSize, associates, r, q] = initArrays(obj)
            % Initialize arrays and convenient aliases
            
            %maxAggregateSize = obj.options.maxAggregateSize +
            %0.5*max(0,(2-log10(delta)));
            lam             = obj.options.aggregateSizeExchangeRate;
            D               = obj.D;
            W               = obj.level.g.adjacency;
            
            % Only consider neighbors (i,j) for which c(i,j) >= threshold
            % Note: c depends on x, which changes with aggregation stages
            x               = obj.x;
            aggregateSize   = obj.aggregateSize;
            associates      = obj.associates;
            
            x2              = 0.5 * x.^2;
            r               = W * x;
            q               = W * x2;
        end
        
        function seeds = initSeedsArray(obj)
            % Initialize the seeds array.
            
            %------------------------------------------------
            % Filter 1: Skip high-degree nodes
            %------------------------------------------------
            if (obj.options.aggregationDegreeThreshold > 0)
                seeds = find(obj.isSeed & (obj.level.g.degree < obj.options.aggregationDegreeThreshold*obj.meanDegree));
            else
                seeds = find(obj.isSeed);
            end
        end
        
        function C = initNbhrLists(obj, W) %#ok<MANU>
            % Initialize neighbor lists. W = adjacency matrix. C(i).index =
            % Ci (active neighbors of node i during the aggregation sweep).
            
            % Allocate affinity struct
            [i, j]      = find(W); % Exclude i-i pairs
            n           = size(W,1);
            C           = repmat(struct('index', zeros(0, 1), 'sz', 0), [n 1]);
            colEnd      = find(diff(j));    % col(k) = end index of A(:,k) in the i,j,Cij arrays
            colEnd(n)   = n;
            
            % Populate struct entries, each corresponding to an A-column
            colBegin = 1;
            for k = 1:n
                if (k > 1)
                    colBegin = colEnd(k-1)+1;
                end
                colKEnd     = colEnd(k);
                index       = i(colBegin:colKEnd)';
                C(k).index  = index;
                C(k).sz     = numel(index); % Keeps track of # active elements in index, value
            end
        end
        
        function c = computeAffinities(obj, x, i, index, subtractMean) %#ok<MANU>
            % Compute the affinities c between x_i and x_{index}.
            nRows   = numel(index);
            ind     = ones(nRows,1);
            X       = x(i,:);
            Y       = x(index,:);
            if (subtractMean)
                nCols   = size(Y,2);
                cols    = ones(nCols,1);
                X       = X - mean(X);
                meanY   = mean(Y,2);
                meanY   = meanY(:,cols);
                Y       = Y - meanY;
            end
            X       = X(ind,:);         % Inlined repmat
            
            % Calculate affinities C(X,Y)
            c       = (sum(X.*Y, 2)).^2 ./ (sum(X.*X, 2) .* sum(Y.*Y, 2));
        end
        
        function [X, Ec, E] = computeEnergies(obj, x, D, r, q, i, index) %#ok<MANU>
            % For each candidate j in index and each TV, find the TV value
            % X over the prospective aggregate (i,j) that minimizes the
            % local coarse energy Ec(X) = Ei+Ej
            nRows   = numel(index);
            rows    = ones(nRows,1);
            xi      = x(i,:);
            xi      = xi(rows,:);
            xindex  = x(index,:);
            
            % Numerator of X expression
            ri      = r(i,:);
            ri      = ri(rows,:);
            rindex  = r(index,:);
            R       = ri + rindex;
            nCols   = size(R,2);
            cols    = ones(nCols,1);
            
            % Denominator of X expression
            di      = D(i);
            di      = di(rows,cols);
            dindex  = D(index);
            dindex  = dindex(:,cols);
            d       = di + dindex;
            X       = R./d;
            
            % Compute local energy after aggregation
            qi      = q(i,:);
            qi      = qi(rows,:);
            qindex  = q(index,:);
            Q       = qi + qindex;
            Ec      = 0.5*d.*X.^2 - R.*X  + Q;
            
            % Compute local energy nefore aggregation, i.e. min{xi,xindex}
            % [Ei + Eindex]. This requires solving a 2x2 system for xi,xs.
            % To turn off and use the original TV Ei(xi)+Es(xs), simply
            % comment out xi, xindex's assignments below.
            %                 w       = W(index, i); w       =
            %                 w(:,cols); a11     = di + w; a22     = dindex
            %                 + w; a12     = 2*w; b1      = ri - w.*xindex;
            %                 b2      = rindex - w.*xi; determ  =
            %                 1./(a11.*a22 - a12.*a12); xi =
            %                 determ.*(a22.*b1 + a12.*b2); xindex  =
            %                 determ.*(a12.*b1 + a11.*b2);
            E       = ...
                0.5*di.*xi.^2         - ri.*xi         + qi + ...
                0.5*dindex.*xindex.^2 - rindex.*xindex + qindex;
        end
        
        function [r, q] = updateEnergyTerms(obj, r, q, W, x, cols, Ts, xAggregate) %#ok<MANU>
            % Update the r- and q- terms of all neighbors k of Ts after x
            % was set to xAggregate on Ts.
            
            % For each s-associate j, update the r- and q- terms of its
            % neighbors.
            for j = Ts
                % Get neighbors k
                [k, dummy, akj] = find(W(:,j)); %#ok
                rows        = ones(numel(k),1);
                akj         = akj(:,cols);
                
                xNew        = xAggregate(rows,:);
                xOld        = x(j,:);
                xOld        = xOld(rows,:);
                
                % Update r-, q- terms
                dr          = akj .* (xNew - xOld);
                dq          = 0.5 * akj .* (xNew.^2 - xOld.^2);
                r(k,:)      = r(k,:) + dr;
                q(k,:)      = q(k,:) + dq;
            end
        end
        
        function [associates, aggregateSize] = updateAssociateLists(...
                obj, i, s, associates, aggregateSize)
            % Update associate lists
            Ti                   = associates(i).list;
            Ni                   = numel(Ti);
            Ns                   = numel(associates(s).list);
            associates(s).list(Ns+1:Ns+Ni)  = Ti;
            obj.seed(Ti)         = s;
            obj.isSeed(Ti)       = false;
            aggregateSize(s)     = aggregateSize(s)+Ni;
        end
        
        function C = updateNbhrLists(obj, i, s, C)
            % Purpose: update affinities among nodes upon aggregation.
            % Input: i = node to be aggregated with the seed s. Must be a
            % seed of an existing aggregate. s = seed to aggregate i into
            
            % Cs = (Cs U Ci) \ {s,i}.
            %   Inline the command j = union(obj.C(i).index,
            %   obj.C(s).index)
            a = [obj.C(i).index, obj.C(s).index];
            j = sort(a); j(j(1:end-1) == j(2:end)) = [];
            j = j((obj.seed(j) == j) & (j ~= s) & (j ~= i));
            
            % Update the corresponding C-columns to keep C symmetric
            numNewNeighbors = numel(j);
            for m = 1:numNewNeighbors
                k        = j(m);
                sz       = obj.C(k).sz;
                index    = obj.C(k).index;
                location = find(index == s, 1, 'first');
                if (isempty(location))
                    % Append s to k's affinities
                    obj.C(k).sz              = sz+1;
                    location                 = sz+1;
                    obj.C(k).index(location) = s;
                else
                    % Update s's existing value in k's affinities
                    %obj.C(k).value(location) = csk;
                end
                
                % Deactivate i's affinity (faster than removing its entry)
                % by swapping it with the last element and decrementing the
                % list size. Works even if i is the last element.
                sz                          = obj.C(k).sz;
                %index                       = obj.C(k).index(1:sz);
                index                       = obj.C(k).index;
                location                    = find(index == i, 1, 'first');
                if (~isempty(location))
                    % Splitting to two lines is MUCH faster than setting
                    % index(location)<-index(sz) in one line!
                    temp                        = obj.C(k).index(sz);
                    obj.C(k).index(location)    = temp;
                    obj.C(k).sz                 = sz-1;
                end
            end
            
            % Update s's neighbor list
            obj.C(s).index  = j;
            obj.C(s).sz     = numNewNeighbors;
        end
    end
end