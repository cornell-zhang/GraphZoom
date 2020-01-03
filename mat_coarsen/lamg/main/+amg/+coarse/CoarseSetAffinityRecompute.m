classdef (Hidden, Sealed) CoarseSetAffinityRecompute < amg.coarse.CoarseSet
    %COARSESET A coarse aggregate set of a fine-level graph.
    %   This class is the main data structure used during aggregation
    %   stages.
    %
    %   @DEPRECATED
    %   See also: AGGREGATORHCR.
    
    %=========================== PROPERTIES ==============================
    properties (Constant, GetAccess = private)
        myLogger = core.logging.Logger.getInstance('amg.coarse.CoarseSetAffinityRecompute')
    end
    
    %======================== CONSTRUCTORS ============================
    methods
        function obj = CoarseSetAffinityRecompute(level, associateHolder, options)
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
            
            % Compute i-affinities to its seed neighbors (index). Use total
            % variance, not average variance
            index  = find(obj.W(:,i));
            index  = index(obj.isSeed(index));
            if (isempty(index))
                s = 0;
            else
                % Compute affinities - inlined for speed
                % c = affinity_l2(obj.x(i,:), obj.x(index,:));
                c = obj.affinity(i, index);
                
                % Find the best seed in the set index
                j = find(c >= delta);
                if (isempty(j))
                    s = 0;
                else
                    % Introduce a slight favoritism towards smaller
                    % aggregates
                    index   = index(j);
                    value   = c(j);
                    alphaJ  = obj.aggregateSize(index);
                    alphaI  = obj.aggregateSize(i);
                    e       = 0.1*(1-delta);
                    [dummy, k]  = max(value ./ (1-e + e*(alphaI + alphaJ - 1))); %#ok
                    s       = index(k(1));
                end
            end
            
            % Debugging printouts
            if (0) %(true)
                fprintf('i = %d  best seed s = %d\n', i, s);
                index   = find(obj.W(:,i));
                [c, X, Y] = obj.affinity(i, index);
                X = X(1,:)';
                Y = Y';
                cNoWeight = obj.affinity(i, index);
                disp([index obj.isSeed(index)' full(obj.W(index,i)) c cNoWeight]);
                if (i==19)
                    plot([X Y]);
                    %aaa=0;
                end
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
        end
    end
    
    %======================== PRIVATE METHODS =========================
    methods (Access = private)
        function C = affinityMatrix(obj, dummy1, dummy2, dummy3) %#ok
            % Return the initial affinity matrix containing node-node
            % affinities.
            C = [];
        end
        
        function [c, X, Y] = affinity(obj, i, index)
            % TODO: remove sx, sy args after debugging is done
            
            nRows   = numel(index);
            ind     = ones(nRows,1);
            
            % Calculate X, Y
            X       = obj.x(i,:);
            Y       = obj.x(index,:);
            if (obj.subtractMean)
                X = X - mean(X);
                Y = Y - repmat(mean(Y,2), 1, size(Y,2));
            end
            X       = X(ind,:);         % Inlined repmat
            
            % Calculate affinities C(X,Y)
            c       = (sum(X.*Y, 2)).^2 ./ (sum(X.*X, 2) .* sum(Y.*Y, 2));
        end
    end
end