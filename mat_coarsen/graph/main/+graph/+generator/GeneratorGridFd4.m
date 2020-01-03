classdef (Hidden, Sealed) GeneratorGridFd4 < graph.generator.AbstractGeneratorGrid
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
        function obj = GeneratorGridFd4(options)
            % Grid constructor.
            obj = obj@graph.generator.AbstractGeneratorGrid(options, 'fd4');
        end
    end
    
    %======================== IMPL: AbstractGenerator Grid ============
    methods
        function s = buildStencil(obj, dummy) %#ok
            % Build the Laplacian FD stencil.
            d = obj.dim;
            s = [];
            for i = 1:d
                if (obj.normalized)
                    factor = 1;
                else
                    factor = 1./(12*obj.h(d)^2);
                end
                s = [s; ...
                    [-2*uv(d,i)   -factor]; ...
                    [-1*uv(d,i) 16*factor]; ...
                    [ 1*uv(d,i) 16*factor]; ...
                    [ 2*uv(d,i)   -factor]; ...
                    ]; %#ok
            end
        end
    end
end
