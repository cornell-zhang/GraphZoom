classdef (Hidden, Sealed) GeneratorLoosePath < amg.api.Builder
    %GENERATORGRID Loose path graph generator.
    %   OBJ=graph.generator.GeneratorLoosePath(OPTIONS) generates the graph of a
    %   one-dimensional uniform grid graph (path graph) of size OPTIONS.N)) over
    %   [0,1]. N must be even. The middle strength connection between vertices
    %   N(2) and N(2)+1 is set to OPTIONS.E, so if E=1 this is an isotropic
    %   grid, and as E->0 we obtain two weakly connected components.
    %
    %   See also: GRAPH, GENERATORGRID.
    
    %=========================== PROPERTIES ==============================
    properties (GetAccess = private, SetAccess = private)
        e           % Inter-component connection strength
        n           % Grid size
        h           % Grid meshsize
    end
    
    %=========================== CONSTRUCTORS ============================
    methods
        function obj = GeneratorLoosePath(options)
            %Path grid constructor.
            
            % Argument validation. Must specify either size or h.
            if  (isempty(options.n))
                error('MATLAB:BatchReader:parseArgs', 'Must specify either grid size (n)');
            end
            if  (isempty(options.e))
                error('MATLAB:BatchReader:parseArgs', 'Must specify connection strength (e)');
            end
            
            obj.n = options.n;
            obj.h = 1./options.n;
            obj.e = options.e;
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
            % Compute grid point indices locations.
            i     = (1:obj.n)';
            coord = (i-1)*obj.h;
        end
        
        function edges = buildEdges(obj, i)
            % Compute the graph's adjacency list.
            iLeft  = i(1:end-1);
            iRight = iLeft+1;
            edges   = [iLeft iRight ones(obj.n-1,1)];
            edges(floor(obj.n/2),3) = obj.e;
        end
        
        function metadata = buildMetadata(obj)
            % Generate graph meta data.
            metadata            = graph.api.GraphMetadata;
            metadata.formatType = graph.api.GraphFormat.GENERATED;
            metadata.graphType  = graph.api.GraphType.UNDIRECTED;
            metadata.numNodes   = obj.n;
            metadata.numEdges   = numel(obj.n-2);
            metadata.group      = 'generated';
            name                = sprintf('path-%d-%.1e', obj.n, obj.e);
            metadata.name       = name;
            
            % Special attributes of this graph family
            metadata.attributes.dim = 1;
            metadata.attributes.n   = obj.n;
            metadata.attributes.h   = obj.h;
            metadata.attributes.e   = obj.e;
        end
        
    end
end
