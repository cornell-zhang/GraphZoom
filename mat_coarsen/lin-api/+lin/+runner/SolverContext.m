classdef (Hidden, Sealed) SolverContext < handle
    %SolverContext Global solver context.
    %   This class acts like a Spring application context. It is shared by
    %   all solver instances run by RunnerSolvers.
    %
    %   See also: SOLVER, RUNNERSOLVERS, RUNNERSOLVER.
    
    %=========================== PROPERTIES ==============================
    properties (Constant, GetAccess = private)
        logger = core.logging.Logger.getInstance('lin.runner.SolverContext')
    end
    
    properties (GetAccess = private, SetAccess = private)
        % Dependencies
        contexts         % Map of (shared-)solver-key - to - shared solver data
    end
    
    %======================== METHODS ====================================
    methods
        function obj = SolverContext()
            obj.contexts = containers.Map();
        end
    end
    
    %======================== METHODS ====================================
    methods
        function createSolverKey(obj, key)
            % Add a new solver shared key to the context map if it does not
            % yet exist. Create an empty context for the key. If key is
            % empty, this method has no ffect.
            if (~isempty(key) && ~obj.contexts.isKey(key))
                obj.contexts(key) = containers.Map();
            end
        end
        
        function clear(obj)
            % Clear all context data. Does not modify keys, only the
            % internals of each context object.
            for key = obj.contexts.keys
                context = obj.contexts(key{:});
                context.remove(context.keys);
            end
        end
        
        function clearLargeObjects(obj, varargin)
            % Clean large objects from context. Currently, this method is
            % hard-coded to clearing setup objects. If ignoreList is
            % specified, ignores context names in that cell array.
            
            if (nargin < 2)
                ignoreList = {};
            else
                ignoreList = varargin{1};
            end
            % Make sure setup gets cleaned from memory
            for k = obj.contexts.keys
                key = k{:};
                if (~any(strcmp(key, ignoreList)))
                    context = obj.contexts(key);
                    if (context.isKey('setup'))
                        setup = context('setup'); %#ok
                        clear setup;
                    end
                end
            end
            % Now clear the rest of the context
            obj.clear();
        end
        
        function value = getData(obj, key, name)
            % Get the value of a name-value pair in the context of the key
            % KEY.
            if (obj.contexts.isKey(key))
                context = obj.contexts(key);
                if (context.isKey(name))
                    value = context(name);
                else
                    value = [];
                end
            else
                value = [];
            end
        end
        
        function setData(obj, key, name, value)
            % Save the name-value pair in the context of the key KEY,
            % overriding the existing pair, if found.
            context = obj.contexts(key);
            context(name) = value; %#ok
        end
    end
        
    %======================== PRIVATE METHODS =========================
    methods (Access = private)
    end
end
