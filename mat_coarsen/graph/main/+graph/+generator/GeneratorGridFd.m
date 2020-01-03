classdef (Hidden, Sealed) GeneratorGridFd < graph.generator.AbstractGeneratorGrid
    %GeneratorGridFd Grid graph generator.
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
    properties (GetAccess = private, SetAccess = private)
    end
    
    %=========================== CONSTRUCTORS ============================
    methods
        function obj = GeneratorGridFd(options)
            % Grid constructor.
            obj = obj@graph.generator.AbstractGeneratorGrid(options, 'fd');
        end
    end
    
    %======================== IMPL: AbstractGenerator Grid ============
    methods
        function s = buildStencil(obj, dummy) %#ok
            % Build the Laplacian FD stencil.
            d = obj.dim;
            s = [[eye(d) 1./obj.h.^2']; [-eye(d) 1./obj.h.^2']];
            if (obj.normalized)
                s(:,d+1) = 1;
            end
        end
    end
end
