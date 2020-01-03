classdef (Hidden, Sealed) NbhrFinderPeriodic < graph.generator.NbhrFinder
    %NbhrFinderNeumann Grid graph neighbor index finder - periodic B.C.
    %   Finds node indices of grid graph neighbors. Assumes periodic B.C. at all
    %   grid boundaries.
    %
    %   See also: NbhrFinder.
    
    %=========================== CONSTRUCTORS ============================
    methods
        function obj = NbhrFinderPeriodic(options)
            obj = obj@graph.generator.NbhrFinder(options);
        end
    end
    
    %=========================== IMPL: NbhrFinder ========================
    methods
        function interior = findInteriorIndices(obj, i) %#ok<MANU>
            % Return the indices of the subscript arrays i corresponding to
            % interior gridpoints in a grid of size n.
            
            % Periodic domain has only interior points
            interior = (1:numel(i{1}))';
        end
             
        function j = sub2ind(obj, i)
            % Convert subscripts to indices in this boundary condition
            % context.
            
            % Apply periodicity to subscripts; 1-based indices
            iInterior = cell(numel(i), 1);
            for d = 1:obj.options.dim
                nd = obj.options.n(d);
                iInterior{d} = mod(i{d}+nd-1,nd)+1;
            end
            
            % Convert from subscripts to indices
            if (obj.options.dim == 1)
                j = iInterior{1};
            else
                j = sub2ind(obj.options.n, iInterior{:});
            end
        end
    end
end

