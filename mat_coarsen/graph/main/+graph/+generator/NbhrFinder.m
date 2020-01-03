classdef (Hidden) NbhrFinder < amg.api.HasOptions
    %NbhrFinderNeumann Grid graph neighbor index finder interface.
    %   Finds node indices of grid graph neighbors.
    %
    %   See also: NbhrFinder.
    
    %=========================== CONSTRUCTORS ============================
    methods
        function obj = NbhrFinder(options)
            %Grid constructor.
            obj = obj@amg.api.HasOptions(options);
        end
    end
    
    %=========================== ABSTRACT METHODS ========================
    methods (Abstract)
        interior = findInteriorIndices(obj, i)
        % Return the indices of the subscript arrays i corresponding to
        % interior gridpoints in a grid of size n.
        
        j = sub2ind(obj, i)
        % Convert subscripts to indices in this boundary condition
        % context.
    end
end
