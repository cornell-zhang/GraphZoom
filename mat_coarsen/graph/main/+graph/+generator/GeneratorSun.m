classdef (Hidden, Sealed) GeneratorSun < amg.api.Builder
    %GENERATORSUN Sun graph generator.
    %   OBJ=graph.generator.GeneratorSun(OPTIONS) generates an unweighted graph with
    %   one sun and OPTIONS.N-1 satellites.
    %
    %   See also: GRAPH, GENERATORGRID.
    
    %=========================== PROPERTIES ==============================
    properties (GetAccess = private, SetAccess = private)
        n           % Graph size
    end
    
    %=========================== CONSTRUCTORS ============================
    methods
        function obj = GeneratorSun(options)
            %Path grid constructor.
            
            % Argument validation. Must specify either size or h.
            if  (isempty(options.n))
                error('MATLAB:BatchReader:parseArgs', 'Must specify graph size (n)');
            end
            
            obj.n = options.n;
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
            % Compute node coordinates. Satellites circle the sun at the origin.
            alpha = 2*pi/(obj.n-1);
            i     = (1:obj.n-1)';
            coord = [[0 0]; [cos(alpha*i) sin(alpha*i)]];
        end
        
        function edges = buildEdges(obj, dummy) %#ok
            % Compute the graph's adjacency list. sun index=1,
            % satellites=2..n.
            edges = [ones(obj.n-1,1) (2:obj.n)' ones(obj.n-1,1)];
        end
        
        function metadata = buildMetadata(obj)
            % Generate graph meta data.
            metadata            = graph.api.GraphMetadata;
            metadata.formatType = graph.api.GraphFormat.GENERATED;
            metadata.graphType  = graph.api.GraphType.UNDIRECTED;
            metadata.numNodes   = obj.n;
            metadata.numEdges   = obj.n-1;
            metadata.group      = 'sun';
            name                = sprintf('sun-%d', obj.n);
            metadata.name       = name;
            
            % Special attributes of this graph family
            metadata.attributes.dim = 2;
            metadata.attributes.n   = obj.n;
        end
        
    end
end
