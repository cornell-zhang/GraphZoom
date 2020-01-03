classdef (Hidden, Sealed) GeneratorGridStencil < graph.generator.AbstractGeneratorGrid
    %GENERATORGRIDFE General grid stencil grid graph generator.
    %   EDGES=graph.generator.GeneratorGrid(H) generates the graph of the
    %   D-dimensional isotropic Laplacian with Neumann boundary conditions,
    %   discretized on a grid with meshsizes (H(1),...,H(D)) over the
    %   D-dimensional unit cube with finite elements.
    %
    %   NOTE: WORKS ONLY FOR H(1)=...=H(D) for now!!
    %
    %   See also: GRAPH.
    
    %=========================== PROPERTIES ==============================
    properties (GetAccess = private, SetAccess = private)
        s % Cached stencil
    end
    
    %=========================== CONSTRUCTORS ============================
    methods
        function obj = GeneratorGridStencil(options, gridType)
            %Grid constructor.
            obj = obj@graph.generator.AbstractGeneratorGrid(options, gridType);
        end
    end
    
    %======================== IMPL: AbstractGenerator Grid ============
    methods
        function s = buildStencil(obj, options) %#ok<MANU>
            % Build the general stencil. Read from cache.
            s = options.stencil;
        end
    end
end