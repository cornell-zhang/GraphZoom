classdef (Hidden, Sealed) NbhrFinderNeumann < graph.generator.NbhrFinder
    %NbhrFinderNeumann Grid graph neighbor index finder - Neumann B.C.
    %   Finds node indices of grid graph neighbors. Assumes Neumann B.C. at
    %   all grid boundaries.
    %
    %   See also: NbhrFinder.
    
    %=========================== CONSTRUCTORS ============================
    methods
        function obj = NbhrFinderNeumann(options)
            obj = obj@graph.generator.NbhrFinder(options);
        end
    end
    
    %=========================== IMPL: NbhrFinder ========================
    methods
        function interior = findInteriorIndices(obj, i)
            % Return the indices of the subscript arrays i corresponding to
            % interior gridpoints in a grid of size n.
            for d = 1:obj.options.dim
                id = i{d};
                interiorInDimensionD = find((id >= 1) & (id <= obj.options.n(d)));
                if (d == 1)
                    interior = interiorInDimensionD;
                else
                    interior = intersect(interior, interiorInDimensionD);
                end
            end
        end
        
        function j = sub2ind(obj, i)
            % Convert subscripts to indices in this boundary condition
            % context.
            if (obj.options.dim == 1)
                j = i{1};
            else
                j = sub2ind(obj.options.n, i{:});
            end
        end
    end
    
end

