classdef CellExpandingArray < handle
    %CELLEXPANDINGARRAY A list of sparse vectors.
    %   A Java-based implementation of a list of sparse vectors 
    
    properties (GetAccess = private, SetAccess = private)
        n
        data
    end
    
    methods
        function obj = CellExpandingArray(n, z)
            % Create a test cell array of size n.
            obj.n   = n;
            obj.data = repmat(struct('index', zeros(0, 1), 'value', zeros(0, 1)), [n 1]);
        end
        
        function addEntriesToLists(obj, z)
            % Add z random entries to each element of data.
            for j = 1:z
                for i = 1:obj.n
                    % Seems like MATLAB takes care well of reallocation
%                     oldList = obj.data(i).index;
%                     sz = numel(oldList);
%                     if (sz < j)
%                         % Reallocate to a twice longer list
%                         obj.data(i).index = zeros(2*sz, 1);
%                         obj.data(i).index(1:sz) = oldList;
%                     end
                    obj.data(i).index(j) = j;
                    obj.data(i).value(j) = j;
                end
            end
        end
        
        function findEntries(obj, z)
            % Find z entries per element of data and set entries to new values.
            for j = 1:z
                for i = 1:obj.n
                    index = obj.data(i).index;
                    obj.data(i).value(index == j) = 1.0;
                end
            end
            % TBA
        end

    end
end
