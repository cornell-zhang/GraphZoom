classdef (Sealed) Logger < handle
    %LOGGER A MATLAB logger, similar to Log4J for Java.
    %   This class allows setting a global verbosity level (ERROR, WARN,
    %   INFO, DEBUG or TRACE). fprintf printout functions is provided into
    %   which a verbsoity level is passed, for fine-grain-control.
    %
    %   This class assumes that a logging configuration function called
    %   LOGGING_CONFIG exists on the path.
    
    %=========================== PROPERTIES ==============================
    properties (Constant, GetAccess = private)
        ROOT_NAME = 'root';             % Root logger name. No other logger should bear this name.
        DELIMITER = '.';                % Fully-qualified class name delimiter
    end
    properties (GetAccess = public, SetAccess = public)
        name                            % Logger's owning class
        level = 'INFO'                  % Current verbosity level
        lineFormat = {'%-5s  %-10s  %s', 'level', 'simpleName', 'message'};  % Line printout format (up to formatted string), followed by arguments. "level", "message" are interpreted literally; all other arguments are assumed to be Logger field names.
        file                            % File name, if outputting to a file (applied to root logger only right now)
    end
    properties (Dependent)
        errorEnabled
        warnEnabled
        infoEnabled
        debugEnabled
        traceEnabled
    end
    properties (GetAccess = private, SetAccess = private)
        simpleName                      % Caches the simplified class name to print in lineFormat
        parent                          % Reference to parent logger in the Logger tree
    end
    
    %=========================== CONSTRUCTORS ============================
    methods (Access = private)
        function obj = Logger(arg)
            %Construct a class logger.
            %   Examples:
            %
            %       Logger(name) - initialize logger with name "name"
            %
            %       Logger(other) - copy constructor
            if (nargin ~= 1)
                error('MATLAB:Logger:InputArg','Must pass 1 constructor argument');
            elseif ischar(arg)
                obj.name = arg;
            elseif strcmp(class(arg), 'core.logging.Logger')
                % Copy constructor
                obj.name = arg.name;
                obj.level = arg.level;
                obj.lineFormat = arg.lineFormat;
            end
        end
    end
    
    % Factory methods
    methods (Static)
        function obj = getInstance(name)
            %Return a class logger. If it does not appear in the logging
            %configuration, append it to the Logger tree.
            
            % Create the singleton instance of the Logger tree
            persistent localObj;
            if isempty(localObj)
                % Initialize logging
                [root, logger] = logging_config;
                localObj = core.logging.Logger.initialize(root, logger);
            end
            loggers = localObj;
            
            % Look up the requested class logger in the tree. If it is not
            % there, return its closest ancestor.
            if isKey(loggers, name)
                obj = loggers(name);
            else
                % Create a new Logger as a copy of its parent (other than
                % its name), and append it under its parent
                parentLogger = core.logging.Logger.getParentLogger(loggers, name);
                obj = core.logging.Logger(parentLogger);
                obj.name = name;
            end
        end
        
        function setLevel(name, level)
            % Set the level of the logger identified by NAME to LEVEL.
            logger = core.logging.Logger.getInstance(name);
            logger.level = level;
        end
        
        function file = getFile()
            % Get root logger output file.
            logger = core.logging.Logger.getInstance(core.logging.Logger.ROOT_NAME);
            file = logger.file;
        end
        
        function setFile(file)
            % Set output file to FILE.
            logger = core.logging.Logger.getInstance(core.logging.Logger.ROOT_NAME);
            logger.file = file;
        end
    end
    
    %=========================== METHODS =================================
    methods
        function disp(obj)
            fprintf('name: %s\n',obj.name);
            ancestor = obj.parent;
            while (~isempty(ancestor))
                fprintf('parent: %s\n', ancestor.name);
                ancestor = ancestor.parent;
            end
        end
        
        function error(obj, varargin)
            obj.fprintf(core.logging.LogLevel.ERROR, varargin{:});
        end
        
        function warn(obj, varargin)
            obj.fprintf(core.logging.LogLevel.WARN, varargin{:});
        end
        
        function info(obj, varargin)
            obj.fprintf(core.logging.LogLevel.INFO, varargin{:});
        end
        
        function debug(obj, varargin)
            obj.fprintf(core.logging.LogLevel.DEBUG, varargin{:});
        end
        
        function trace(obj, varargin)
            obj.fprintf(core.logging.LogLevel.TRACE, varargin{:});
        end
        
        function fprintf(obj, level, varargin)
            if (obj.level >= level)
                % Print level parameters
                message         = sprintf(varargin{:});
                line            = obj.lineFormat{1};
                lineArgNames    = obj.lineFormat(2:end);
                lineArgs        = cell(size(lineArgNames));
                for i = 1:length(lineArgNames)
                    argName = lineArgNames{i};
                    if (strcmp(argName, 'level'))
                        lineArgs{i} = level.name;
                    elseif (strcmp(argName, 'message'))
                        lineArgs{i} = message;
                    else
                        lineArgs{i} = obj.(argName);
                    end
                end
                fprintf(line, lineArgs{:});
                
                % Print to file, if output file was specified
                outputFile = core.logging.Logger.getFile();
                if (~isempty(outputFile))
                    f = fopen(outputFile, 'a');
                    fprintf(f, line, lineArgs{:});
                    fclose(f);
                end
            end
        end
    end
    
    %=========================== GET & SET ===============================
    methods
        function set.lineFormat(obj, lineFormat)
            obj.lineFormat = lineFormat;
        end
        
        function val = get.errorEnabled(obj)
            val = (obj.level >= core.logging.LogLevel.ERROR);
        end
        
        function val = get.warnEnabled(obj)
            val = (obj.level >= core.logging.LogLevel.WARN);
        end
        
        function val = get.infoEnabled(obj)
            val = (obj.level >= core.logging.LogLevel.INFO);
        end
        
        function val = get.debugEnabled(obj)
            val = (obj.level >= core.logging.LogLevel.DEBUG);
        end
        
        function val = get.traceEnabled(obj)
            val = (obj.level >= core.logging.LogLevel.TRACE);
        end
        
        function set.name(obj, name)
            obj.name = name;
            obj.simpleName = core.logging.Logger.getSimpleName(obj.name); %#ok
        end
    end
    
    %=========================== PRIVATE METHODS =========================
    methods (Static, Access = private)
        function loggers = initialize(root, loggingConfig)
            %Initialize the logging configuration stored in the "loggers"
            %field.
            
            % Configure root logger
            rootLogger              = core.logging.Logger(core.logging.Logger.ROOT_NAME);
            rootLogger.level        = core.logging.LogLevel.valueOf(root.level);
            rootLogger.lineFormat   = root.lineFormat;
            loggers = containers.Map();
            loggers(core.logging.Logger.ROOT_NAME) = rootLogger;
            
            % Configure all loggers by keys (= fully-qualified class names)
            % keys are alphabetically sorted by Map's implementation, i.e.
            % they are in pre-traversal order.
            keys            = loggingConfig.keys;
            key             = core.logging.Logger.ROOT_NAME;
            for i = 1:length(keys)
                % Update references
                prevKey = key;
                key = keys{i};
                
                % Configure logger from input options
                childLogger         = core.logging.Logger(key);
                config              = loggingConfig(key);
                childLogger.level   = core.logging.LogLevel.valueOf(config);
                
                % Add logger under its parent in the tree
                if ((i == 1) || ~isempty(strfind(key, prevKey)))
                    % key is a child of prevKey, set current parent to
                    % prevKey and add key as its child
                    currentParent = loggers(prevKey);
                else
                    % key is not a child of prevKey, climb up the hierarchy
                    % until we find key's parent, and add key under that
                    % parent. Parent is already in loggers because we are
                    % pre-traversing the key list.
                    currentParent = core.logging.Logger.getParentLogger(loggers, key);
                end
                childLogger.parent = currentParent;

                % Inherit child fields that are not allowed to be
                % customized from parent
                childLogger.lineFormat = currentParent.lineFormat;
                
                loggers(key) = childLogger;
            end
        end
        
        function parent = getParentLogger(loggers, name)
            % Note: the following method has quadratic complexity in the
            % number of parts, which should be small, though.
            parts = regexp(name,'\.','split');
            parts(end) = [];
            name = core.logging.Logger.concat(parts, core.logging.Logger.DELIMITER);
            while (~isempty(parts) && ~isKey(loggers, name))
                parts(end) = [];
                name = core.logging.Logger.concat(parts, core.logging.Logger.DELIMITER);
            end
            if (isempty(name))
                parent = loggers(core.logging.Logger.ROOT_NAME);
            else
                parent = loggers(name);
            end
        end
        
        function simpleName = getSimpleName(name)
            parts = regexp(name,'\.','split');
            simpleName = parts{end};
        end
        
        function s = concat(parts, delimiter)
            s = [];
            numParts = length(parts);
            for i = 1:numParts
                s = strcat(s, parts{i});
                if (i < numParts)
                    s = strcat(s, delimiter);
                end
            end
        end
        
    end
end
