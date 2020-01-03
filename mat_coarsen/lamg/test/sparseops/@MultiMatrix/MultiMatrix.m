classdef MultiMatrix < handle
    %MULTIMATRIX A list of sparse vectors, organized in multiple matrices.
    %   Add more documentation here if this class proves to be fast enough.
    
    properties (GetAccess = private, SetAccess = private)
        z           % Size of each buffer matrix
        n           % Number of lists
        data        % Buffer matrix cell array
        sz          % List of list sizes
        next        % next{i} points to the next available row of data{i}
    end
    
    methods
        function obj = MultiMatrix(n, z)
            % Allocate all matrices up front.
            obj.n       = n;
            obj.z       = z;
            m           = ceil(logBase(n, obj.z));
            obj.data    = cell(m, 1);
            obj.next    = ones(1, m);
            obj.sz      = zeros(n, 1);
            for k = 1:m
                obj.data{k} = zeros(n, z+1); % Last column of data{k} = reference to row number in obj.data{k+1}
            end
        end
        
        function addEntry(obj, i, value)
            % Add the entry "value" to list #i.
            
            % Calculate index of the last buffer that list #i occupies
            oldSz       = obj.sz(i);
            newSz       = oldSz + 1;
            remainder   = rem(oldSz, obj.z);
            temp        = oldSz + obj.z - 1;
            k           = mod((temp - rem(temp, obj.z))/obj.z, obj.z);
            
            %i
            %k
            
            if (k == 1)
                % first buffer, all rows are occupied
                row = i;
            elseif (k > 1)
                % Retrieve row reference from previous buffer
                row = obj.data{k-1}(i, obj.sz+1);
            end

            if (remainder == 0)
                % End of current buffer
                
                % Set reference to next buffer
                nextK       = k+1;
                nextRow     = obj.next(nextK);
                if (k > 0)
                    obj.data{k}(row, obj.z+1) = nextRow;
                end
                
                % Increment the next-row counter; set our buffer to the
                % next buffer
                k           = nextK;
                row         = nextRow;
                obj.next(k) = nextRow+1;
            else
                % Current buffer has free space
            end
            
            % Add the value to the appropriate place in the list
            obj.data{k}(row, remainder+1) = value;
            obj.sz(i) = newSz;
        end
        
        function addEntriesToLists(obj, b)
            % Add z random entries to each element of data.
            for j = 1:b
                for i = 1:obj.n
                    obj.addEntry(i, j);
                end
            end
        end
        
        function findEntries(obj, b)
            % Find z entries per element of data.
            %for j = 1:z
            %             for i = 1:obj.n-z
            %                 find(obj.data(i:i+z-1,:) == 2);
            %             end
            %end
        end
    end
end
