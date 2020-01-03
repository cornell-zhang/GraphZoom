classdef (Sealed) Holder < handle
    %HOLDER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (GetAccess = private, SetAccess = private)
        x
    end
    
    methods
        function obj = Holder(m, n)
            obj.x = rand(m,n);
        end
    end
    
    methods
        function assignRow(obj, i, y)
            obj.x(i,:) = y;
        end
    end
    
end
