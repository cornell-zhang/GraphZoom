classdef (Sealed) LogLevel < core.lang.Enum
    %LOGLEVEL An enumerated logging level.
    %   This specifies discrete verbosity levels (ERROR, WARN, INFO, DEBUG
    %   or TRACE), similar to Log4J's.
    
    %=========================== PROPERTIES ==============================
    
    % Exposed Enumerated constants
    properties (Constant)
        ERROR   = core.logging.LogLevel('ERROR', 1)
        WARN    = core.logging.LogLevel('WARN' , 2)
        INFO    = core.logging.LogLevel('INFO' , 3)
        DEBUG   = core.logging.LogLevel('DEBUG', 4)
        TRACE   = core.logging.LogLevel('TRACE', 5)
    end
    methods (Static, Access = private)
        function values = registerAll(values)
            values = core.logging.LogLevel.registerInstances(values, { ...
                core.logging.LogLevel.ERROR, ...
                core.logging.LogLevel.WARN ...
                core.logging.LogLevel.INFO ...
                core.logging.LogLevel.DEBUG ...
                core.logging.LogLevel.TRACE ...
                });
        end
    end
    
    %=========================== CONSTRUCTORS ============================
    methods (Access = private)
        function obj = LogLevel(name, value)
            %Construct a logging level.
            obj = obj@core.lang.Enum(name, value);
        end
    end
    
    %=========================== METHODS =================================
    methods (Static)
        function obj = valueOf(name)
            values = core.logging.LogLevel.getValues;
            if (~isfield(values, name))
                error('MATLAB:LogLevel:InputArg','Invalid LogLevel enumerated constant name %s', name);
            end
            obj = values.(name);
        end
    end
    
    %=========================== PRIVATE METHODS =========================
    methods (Static, Access = private)
        
        function values = getValues()
            %Construct a singleton instance of the enumerated value struct.
            persistent localObj
            if isempty(localObj) % || isempty(fieldnames(localObj))
                localObj = struct;
                localObj = core.logging.LogLevel.registerAll(localObj);
            end
            values = localObj;
        end
        
        function values = registerInstances(values, instances)
            for i = 1:length(instances)
                instance = instances{i};
                values.(instance.name) = instance;
            end
        end
    end
    
end
