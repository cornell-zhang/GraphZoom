classdef (Hidden) AbstractGeneratorGrid < amg.api.Builder
    %GENERATORGRID Grid graph generator - base class.
    %   EDGES=graph.generator.GeneratorGrid(H) generates the graph of a
    %   D-dimensional isotropic grid with meshsizes (H(1),...,H(D)) over
    %   the D-dimensional unit cube.
    %
    %   This is equivalent to the cell-centered finite-difference
    %   discretization of the D-dimensional Laplace operator with Neumann
    %   boundary conditions. The grid therefore has N(d) points in
    %   dimension d, where H(d)=1/N(d).
    %
    %   See also: GRAPH.
    
    %=========================== PROPERTIES ==============================
    properties (GetAccess = private, Constant)
        NBHR_FINDER_FACTORY = graph.generator.NbhrFinderFactory
    end

    properties (GetAccess = protected, SetAccess = private)
        dim         % Grid dimension
        n           % Grid size
        h           % Grid meshsize
        numNodes    % Total number of gridpoints
        edges       % Graph adjacency list
        normalized  % If true, normalizes the Laplacian to O(1) L1 row sums
        type        % Grid discretization type
        stencil     % Laplacian stencil. Row format: [stencil_nbhr_relative_index(1:d) coef]
        nbhrFinder  % Sets boundary conditions
    end
    
    %=========================== CONSTRUCTORS ============================
    methods
        function obj = AbstractGeneratorGrid(options, type)
            %Grid constructor.
            
            % Argument validation
            if  (isempty(options.n))
                error('MATLAB:BatchReader:parseArgs', 'Must specify grid size');
            end
            obj.n           = options.n;
            obj.normalized  = options.normalized;
            
            if (isempty(options.h))
                % No meshsize specified, use h = 1/n in all directions so
                % that domain = unit cube
                obj.h = 1./options.n;
            else
                % Meshsize specified
                obj.h = options.h;
            end
            
            % Initializations
            if (size(obj.h, 1) > 1)
                options.h   = options.h';
                obj.h       = obj.h';
            end
            if (size(obj.n, 1) > 1)
                options.n   = options.n';
                obj.n       = obj.n';
            end
            obj.dim         = numel(obj.n);
            obj.numNodes    = prod(obj.n);
            
            obj.type        = type;
            obj.stencil     = obj.buildStencil(options);

            options.dim     = obj.dim;
            obj.nbhrFinder  = graph.generator.AbstractGeneratorGrid.NBHR_FINDER_FACTORY.newInstance(options);
        end
    end
    
    %======================== ABSTRACT METHODS ========================
    methods (Abstract)
        s = buildStencil(obj, options)
        % Build the Laplacian stencil from input options.
    end
    
    %======================== IMPL: Builder ===========================
    methods
        function g = build(obj)
            %Build the grid graph instance G.
            [i, j, coord]   = obj.buildCoord();
            obj.edges       = obj.buildEdges(i, j);
            metadata        = obj.buildMetadata(i);
            g               = graph.api.Graph.newInstanceFromMetadata(metadata, 'edge-list', obj.edges, coord);
            % Back-reference the graph in its metadata so that it can be
            % loaded by a BatchReader
            metadata.attributes.g = g;
        end
    end
    
    %======================== PRIVATE METHODS =========================
    methods (Access = private)
        function [i, j, coord] = buildCoord(obj)
            % Compute subscripts (i(1),...,i(dim)), 1-D indices and
            % spatial locations of all gridpoints with corresponding 1-D
            % indices j=1..nTotal
            j       = (1:obj.numNodes)';
            i       = cell(obj.dim, 1);
            [i{:}]  = ind2sub(obj.n, j);
            coord   = zeros(obj.numNodes, obj.dim);
            for d = 1:obj.dim
                coord(:,d) = (i{d}-0.5)*obj.h(d);
            end
        end
        
        function edges = buildEdges(obj, i, j)
            % Compute the graph's adjacency list.
            
            % Compute neighbor indices (2 neighbors [+,-] per dimension for
            % the dim-dimensional "5-point" stencil analogue
            edges = [];
            
            % Compute edges corresponding to one stencil entry at a time
            s = obj.stencil;
            iNbhrRaw = i;
            for k = 1:size(s,1)
                for d = 1:obj.dim
                    iNbhrRaw{d} = i{d} + s(k,d);
                end
                interior = obj.nbhrFinder.findInteriorIndices(iNbhrRaw);
                iNbhr    = cellfun(@(x)(x(interior)), iNbhrRaw, 'UniformOutput', false);
                jNbhr    = obj.nbhrFinder.sub2ind(iNbhr);
                edges    = [edges; ...
                    [j(interior) jNbhr repmat(s(k,d+1), size(interior))]]; %#ok - this is done within a small loop
            end
            % Graph is symmetric; truncate to upper-triangular part
            edges(edges(:,1) >= edges(:,2),:) = [];
        end
        
        function metadata = buildMetadata(obj, i)
            % Generate graph meta data.
            metadata            = graph.api.GraphMetadata;
            metadata.formatType = graph.api.GraphFormat.GENERATED;
            metadata.graphType  = graph.api.GraphType.UNDIRECTED;
            metadata.numNodes   = obj.numNodes;
            metadata.numEdges   = numel(obj.edges);
            metadata.group      = 'generated';
            fullName            = sprintf('grid-%s-%d', obj.type, obj.n(1));
            if (obj.dim > 1)
                fullName = [fullName sprintf('x%d', obj.n(2:end))];
            end
            metadata.name       = fullName;
            
            % Special attributes of this graph family
            metadata.attributes.dim         = obj.dim;
            metadata.attributes.n           = obj.n;
            metadata.attributes.h           = obj.h;
            metadata.attributes.subscript   = i;
        end
    end
end
