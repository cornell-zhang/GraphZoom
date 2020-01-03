classdef (Hidden, Sealed) GeneratorGridFe < graph.generator.AbstractGeneratorGrid
    %GENERATORGRIDFE Finite-element grid graph generator.
    %   EDGES=graph.generator.GeneratorGrid(H) generates the graph of the
    %   D-dimensional isotropic Laplacian with Neumann boundary conditions,
    %   discretized on a grid with meshsizes (H(1),...,H(D)) over the
    %   D-dimensional unit cube with finite elements.
    %
    %   NOTE: WORKS ONLY FOR H(1)=...=H(D) for now!!
    %
    %   See also: GRAPH.
    
    %=========================== PROPERTIES ==============================
    
    %=========================== CONSTRUCTORS ============================
    methods
        function obj = GeneratorGridFe(options)
            %Grid constructor.
            obj = obj@graph.generator.AbstractGeneratorGrid(options, 'fe');
        end
    end
    
    %======================== IMPL: AbstractGenerator Grid ============
    methods
        function s = buildStencil(obj, dummy) %#ok
            % Build the Laplacian FD stencil.
            d = obj.dim;
            s = harmonics(d,3)-1;
            % Remove diagonal element
            s(max(abs(s),[],2)==0,:) = [];
            % Add coefficients
            s = [s ones(3^d-1,1)];
        end
    end
end