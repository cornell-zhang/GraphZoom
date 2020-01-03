classdef (Hidden, Sealed) AssociateHolder < handle
    %ASSOCIATEHOLDER A data structure that holds seed associate lists.
    %   This class may hopefully reduce the computational complexity of
    %   managing associate lists in MATLAB.
    %
    %   See also: AGGREGATORHCR.
    
    %=========================== PROPERTIES ==============================
    properties (GetAccess = public, SetAccess = private) % public API, immutable
        numAggregates       % Aggregate number counter (nc)
        seed                % Index array. seed(i) is the fine-level node index of the aggregate seed with which i is associated.
        fixedPattern        % Is coarsening pattern fixed by this class or dynamically determined later by other classes
        associates          % A struct array of size n. associates(i).list holds the list of immediate associates of seed i's aggregates.
    end
    
    %======================== CONSTRUCTORS ============================
    methods (Access = private)
        function obj = AssociateHolder(numAggregates, seed, ...
                associates, fixedPattern)
            % Initialize an associate structure for n nodes. Each node is
            % its own aggregate
            obj.numAggregates   = numAggregates;
            obj.seed            = seed;
            obj.associates      = associates;
            obj.fixedPattern    = fixedPattern;
        end
    end
    
    methods (Static) % factory methods
        function obj = newEmpty(n)
            % Return a new empty association holder.
            obj = amg.coarse.AssociateHolder(n, 1:n, ...
                repmat(struct('list', 1), [n 1]), false);
            % Initial associate list of i = {i}
            for i = 1:n
                obj.associates(i).list = i;
            end
        end
        
        function obj = newFixedPattern(numAggregates, seed)
            % Return a new empty association holder.
            obj = amg.coarse.AssociateHolder(numAggregates, seed, ...
                [], true);
        end
    end
end