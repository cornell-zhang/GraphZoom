classdef Enum < handle
    %ENUM An Java-enumerated-like object.
    %   An ENUM is a class with a comparable VALUE field. Useful as a base
    %   class of enumerated types.
    
    %=========================== PROPERTIES ==============================
    properties (GetAccess = public, SetAccess = private)
        name    % Enumerated constant name
        value   % Ordinal value of the constant
    end
    
    %=========================== CONSTRUCTORS ============================
    methods (Access = protected)
        function obj = Enum(name, value)
            %Construct an enumerated type.
            obj.name = name;
            obj.value = value;
        end
    end
    
    %=========================== METHODS =================================    
    methods        
        function disp(obj)
            % Print a log level
            disp(obj.name);
        end
    end
    
    %=========================== METHODS: OPERATIONS =====================
    
    % All relational operators are defined, based on Enum values
    methods (Sealed)
        function r = eq(obj1, obj2)
            r = core.lang.Enum.operateOnValues(@eq, obj1, obj2);
        end
        
        function r = ne(obj1, obj2)
            r = core.lang.Enum.operateOnValues(@ne, obj1, obj2);
        end
        
        function r = gt(obj1, obj2)
            r = core.lang.Enum.operateOnValues(@gt, obj1, obj2);
        end
        
        function r = ge(obj1, obj2)
            r = core.lang.Enum.operateOnValues(@ge, obj1, obj2);
        end
        
        function r = lt(obj1, obj2)
            r = core.lang.Enum.operateOnValues(@lt, obj1, obj2);
        end
        
        function r = le(obj1, obj2)
            r = core.lang.Enum.operateOnValues(@le, obj1, obj2);
        end
    end
    
    %=========================== PRIVATE METHODS =========================
    methods (Static, Access = private)
        function r = operateOnValues(op, obj1, obj2)
            % Useful delegating method for all relational operators.
            r = op(obj1.value, obj2.value);
        end
    end    
end
