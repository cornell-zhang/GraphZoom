classdef (Hidden, Sealed) CoarseSetAffinityMatrix < amg.coarse.CoarseSet
    %COARSESET A coarse aggregate set of a fine-level graph.
    %   This class is the main data structure used during aggregation
    %   stages.
    %
    %   @DEPRECATED
    %   See also: AGGREGATORHCR.
    
    %=========================== PROPERTIES ==============================
    properties (Constant, GetAccess = private)
        myLogger = core.logging.Logger.getInstance('amg.coarse.CoarseSet')
    end
     
    properties (GetAccess = private, SetAccess = private)  % Internal data structures
        C                   % C (nc x nc) = sparse affinity matrix in compressed row format. This is a cell array of row data. row i holds an array of [j, aij], sorted by descending aij (aij assumed to be positive)
    end
    
    %======================== CONSTRUCTORS ============================
    methods
        function obj = CoarseSetAffinityMatrix(level, associateHolder, options)
            % Initialize this object to the empty coarse aggregate set.
            obj = obj@amg.coarse.CoarseSet(level, associateHolder, options);
            
            if (~associateHolder.fixedPattern)
                % Compute initial node affinities between direct graph
                % neighbors. Since MATLAB uses compressed-column
                % format, access columns and convert them to C-rows
                obj.C = obj.affinityMatrix(level.A, obj.x);
            end
        end
    end
    
    %======================== IMPL: CoarseSet =========================
    methods (Access = protected)
        function s = bestSeedInternal(obj, i, delta)
            % Purpose: return the an aggregate seed s to associate a node i
            % with. Input:
            %     i = associate node delta = affinity strength threshold
            % Output: seed node index s to associate i with, or 0, if no
            % such node is found.
            % Find all strong affinities
            j = find(obj.C(i).value(1:obj.C(i).sz) >= delta);
            if (isempty(j))
                s = 0;
            else
                % Introduce a slight favoritism towards smaller aggregates
                index   = obj.C(i).index(j);
                value   = obj.C(i).value(j);
                alphaJ  = obj.aggregateSize(index)';
                alphaI  = obj.aggregateSize(i);
                e       = 0.1*(1-delta);
                [dummy, k] = max(value ./ (1-e + e*(alphaI + alphaJ - 1))); %#ok
                s       = obj.C(i).index(j(k(1)));
            end
        end
        
        function postUpdate(obj, i, s)
            % Purpose: update affinities among nodes upon aggregation.
            % Input: i = node to be aggregated with the seed s. Must be a
            % seed of an existing aggregate. s = seed to aggregate i into

            % Average TVs on the new aggregate s
            ti              = obj.aggregateSize(i);
            ts              = obj.aggregateSize(s);
            factor          = 1.0/(ti+ts);
            obj.x(s,:)      = factor*(ts*obj.x(s,:) + ti*obj.x(i,:));

            % Cs = (Cs U Ci) \ {s,i} Inline the command j =
            % union(obj.C(i).index, obj.C(s).index)
            a = [obj.C(i).index, obj.C(s).index];
            j = sort(a); j(j(1:end-1) == j(2:end)) = [];
            j = j((obj.seed(j) == j) & (j ~= s) & (j ~= i));
            
            % Recompute s-affinities
            % Use total variance, not average variance
            csj = obj.affinityComputer(obj.x(s,:), obj.x(j,:));
            
            % Update the corresponding C-columns to keep C symmetric
            numNewNeighbors = numel(j);
            for m = 1:numNewNeighbors
                k                   = j(m);
                csk                 = csj(m);
                sz                  = obj.C(k).sz;
                %index = obj.C(k).index(1:sz);
                index               = obj.C(k).index;
                location            = find(index == s, 1, 'first');
                if (isempty(location))
                    % Append s to k's affinities
                    obj.C(k).sz              = sz+1;
                    location                 = sz+1;
                    obj.C(k).index(location) = s;
                    obj.C(k).value(location) = csk;
                else
                    % Update s's existing value in k's affinities
                    obj.C(k).value(location) = csk;
                end
                
                % Deactivate i's affinity (faster than removing its entry)
                % by swapping it with the last element and decrementing the
                % list size. Works even if i is the last element.
                sz                          = obj.C(k).sz;
                %index                       = obj.C(k).index(1:sz);
                index                       = obj.C(k).index;
                location                    = find(index == i, 1, 'first');
                if (~isempty(location))
                    % Splitting to two lines is WAY faster than setting
                    % index(location)<-index(sz) in one line!
                    temp                        = obj.C(k).index(sz);
                    obj.C(k).index(location)    = temp;
                    temp                        = obj.C(k).value(sz);
                    obj.C(k).value(location)    = temp;
                    obj.C(k).sz                 = sz-1;
                end
            end
            
            % Update s-affinities
            obj.C(s).index  = j;
            obj.C(s).value  = csj';
            obj.C(s).sz     = numNewNeighbors;
        end
    end
    
    %======================== PRIVATE METHODS =========================
    methods (Access = private)
        function C = affinityMatrix(obj, A, x) %#ok>MANU>
            % Return the initial affinity matrix containing node-node
            % affinities.
            
            % Compute all affinities between nearest graph neighbors
            [i, j]  = find(A - diag(diag(A))); % Exclude i-i pairs
            % Affinity computation strategy in forming the initial affinity matrix
            affinityComputerInitial = @amg.coarse.affinity_l2;
            % Note: aggregate sizes are ti=tj=1 here
            Cij     = affinityComputerInitial(x(i,:), x(j,:));
            
            % Allocate affinity struct
            n           = cols(A);
            C           = repmat(struct('index', zeros(0, 1), 'value', zeros(0, 1)), [n 1]);
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
                C(k).value  = Cij(colBegin:colKEnd)';
                C(k).sz     = numel(index); % Keeps track of # active elements in index, value
            end
        end       
    end
end