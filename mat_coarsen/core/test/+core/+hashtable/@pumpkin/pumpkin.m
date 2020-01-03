classdef (Sealed) pumpkin
    properties
        val
    end
    methods
        function obj = pumpkin(val)
            obj.val = val;
        end
        
        function result = eq(obj1, obj2)
            result = (obj1.val == obj2.val);
        end
    end
end
