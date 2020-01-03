classdef HasArgs < amg.api.HasOptions
    %HASARGS An object that depends on an extra argument list.
    %   This is a base interface for all services that use optional
    %   parameters, usually passed in VARARGIN and parsed using an
    %   INPUTPARSER.
    %
    %   See also: HASOPTIONS, INPUTPARSER.
    
    %======================== MEMBERS =================================
    properties (GetAccess = protected, SetAccess = protected)
        args                % Extra arguments - struct
    end
    
    %======================== CONSTRUCTORS ============================
    methods (Access = protected)
        function obj = HasArgs(varargin)
            % Initialize an argument-dependent object.
            optionsParameter = ~isempty(varargin) && isa(varargin{1}, 'amg.api.Options');
            if (optionsParameter)
                % Construction mode 1: Options and args are passed in
                options = varargin{1};
            else
                % Construction mode 2: only args are passed in
                options = amg.api.Options.fromStruct(amg.api.Options, varargin{:});
            end
            obj = obj@amg.api.HasOptions(options);
            
            % Second parsing pass to set arguments specific to this object
            if (optionsParameter)
                obj.args = obj.parseArgs(varargin{2:end});
            else
                obj.args = obj.parseArgs(varargin{:});
            end
        end
    end
    
    %======================== PRIVATE METHODS =========================
    methods (Abstract, Access = protected)
        args = parseArgs(varargin)
        % Parse a variable argument list into an ARGS struct. Usually
        % implemented using an INPUTPARSER.
    end
end
