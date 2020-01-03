classdef MatrixBased < handle
    %MatrixBased A list of sparse vectors.
    %   A Java-based implementation of a list of sparse vectors 
    
    properties (GetAccess = private, SetAccess = private)
        n
        data
    end
    
    methods
        function obj = MatrixBased(n, z)
            % Create a test cell array of size n.
            obj.n = n;
            obj.data = zeros(n, z);
        end
        
        function addEntriesToLists(obj, z)
            % Add z random entries to each element of data.
            for j = 1:z
                for i = 1:obj.n
                    obj.data(i,j) = j;
                end
            end
        end
        
        function findEntries(obj, z)
            % Find z entries per element of data.
            %for j = 1:z
                for i = 1:obj.n-z
                    find(obj.data(i:i+z-1,:) == 2);
                end
            %end
        end
    end
end
