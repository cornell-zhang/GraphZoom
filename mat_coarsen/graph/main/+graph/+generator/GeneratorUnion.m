classdef (Hidden, Sealed) GeneratorUnion < amg.api.Builder
    %GENERATORUNION Unions two graphs.
    %   OBJ=graph.generator.GeneratorUnion(G1,G2,E) unions G1,G2 into
    %   a single graph. G1's first node is connected to G2's first node
    %   with edge weight E.
    %
    %   See also: GRAPH, GENERATORGRID.
    
    %=========================== PROPERTIES ==============================
    properties (GetAccess = private, SetAccess = private)
        e           % Inter-graph connection strength
        g1          % First graph
        g2          % Second graph
    end
    
    %=========================== CONSTRUCTORS ============================
    methods
        function obj = GeneratorUnion(g1, g2, e)
            %Union graph constructor.
            obj.g1 = g1;
            obj.g2 = g2;
            obj.e  = e;
        end
    end
    
    %======================== IMPL: Builder ===========================
    methods
        function g = build(obj)
            %Build the grid graph instance G.
            [i, coord]      = obj.buildCoord();
            edges           = obj.buildEdges(i);
            metadata        = obj.buildMetadata();
            g               = graph.api.Graph.newInstanceFromMetadata(metadata, 'edge-list', edges, coord);
            % Back-reference the graph in its metadata so that it can be
            % loaded by a BatchReader
            metadata.attributes.g = g;
        end
    end
    
    %======================== PRIVATE METHODS =========================
    methods (Access = private)
        function [i, coord] = buildCoord(obj)
            % Compute grid point indices locations. Shift g2 w.r.t. to g1.
            i     = [];
            maxCoord = max(obj.g1.coord(:,end)) - min(obj.g2.coord(:,end)) + 0.1; % Add offset to separate the two graphs a little
            coord = [obj.g1.coord; obj.g2.coord + repmat(maxCoord, size(obj.g2.coord))];
        end
        
        function edges = buildEdges(obj, dummy) %#ok
            % Compute the graph's adjacency list.
            [i, j, a]  = find(tril(blkdiag(obj.g1.adjacency, obj.g2.adjacency)));

            % Node index offsets of the two sub-graphs
            offset = [0 obj.g1.numNodes];
            
            if (obj.e == 0)
                edges = [i j a];
            else
                % Non-zero e: connect node 1 of g1 with node 2 of g2 with
                % weight e
                edges  = [[i j a]; [offset(1)+1 offset(2)+1 obj.e]];
            end
        end
        
        function metadata = buildMetadata(obj)
            % Generate graph meta data.
            metadata            = graph.api.GraphMetadata;
            metadata.formatType = graph.api.GraphFormat.GENERATED;
            metadata.graphType  = graph.api.GraphType.UNDIRECTED;
            metadata.numNodes   = obj.g1.numNodes + obj.g2.numNodes;
            metadata.numEdges   = obj.g1.numEdges + obj.g2.numEdges + 1;
            metadata.group      = 'generated';
            name                = sprintf('union-%s-%s-%.1e', ...
                obj.g1.metadata.name, obj.g2.metadata.name, obj.e);
            metadata.name       = name;
            
            % Special attributes of this graph family
            metadata.attributes.e   = obj.e;
        end
        
    end
end
