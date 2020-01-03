classdef ListSparse < handle
    %LISTSPARSE A list of sparse vectors.
    %   A Java-based implementation of a list of sparse vectors 
    
    properties (GetAccess = private, SetAccess = private)
        n
        data
    end
    
    methods
        function obj = ListSparse(n, z)
            % Create a test cell array of size n.
            obj.data = java.util.ArrayList(n);
            obj.n = n;
            for i = 1:n
                obj.data.add(java.util.HashSet);
            end
        end
        
        function addEntriesToLists(obj, z)
            % Add z random entries to each element of data.
            r = randi(8, obj.n*z, 1);
            count = 0;
            for j = 1:z
                for i = 0:obj.n-1
                    count = count+1;
                    %obj.data{i} = intersect(obj.data{i}, r(count));
                    obj.data.get(i).add(r(count));
                end
            end
        end
    end
end

