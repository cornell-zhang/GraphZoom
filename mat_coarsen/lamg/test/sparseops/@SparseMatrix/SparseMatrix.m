classdef SparseMatrix < handle
    %SPARSEMATRIX A list of sparse vectors.
    %   A Java-based implementation of a list of sparse vectors 
    
    properties (GetAccess = private, SetAccess = private)
        n
        data
    end
    
    methods
        function obj = SparseMatrix(n, z)
            % Create a test cell array of size n.
            obj.data = spalloc(n,n,10*n);
            obj.n = n;
        end
        
        function addEntriesToLists(obj, z)
            % Add z random entries to each element of data.
            for j = 1:z
                for i = 1:obj.n
                    obj.data(i,j) = 1.2345;
                end
            end
        end
    end
end

