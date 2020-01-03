classdef CellClass
    %CELLCLASS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        A
    end
    properties (GetAccess = private, SetAccess = private)
        n
        m
    end
    
    methods
        function obj = CellClass(n, m)
            % Create a test cell array of size n.
            a = cell(n,1);
            for i = 1:n
                a{i} = zeros(m, 5);
            end
            
            obj.n = n;
            obj.m = m;
            obj.A = a;
        end
       
        function setCells(obj)
            % Set cells in the cell array.
            for i = 1:obj.n
                % Get test
                obj.A{i}(obj.m,5) = 1.0;
                
                % Set test
                obj.A{i} = zeros(obj.m, 5);
            end
        end
        
        function setEntries(obj)
            % Set entries within a cell's matrix.
            for i = 1:obj.n
                for j = 1:obj.m
                    obj.A{i}(j,1) = 1.0;
                end
            end
        end
        
    end
    
end
