classdef HasOptions < handle
    %HASOPTIONS An object that depends on multigrid options.
    %   This is a base interface for all services that require an Options
    %   object.
    
    %======================== MEMBERS =================================
    properties (GetAccess = protected, SetAccess = protected)
        options             % Input options
    end
    
    %======================== CONSTRUCTORS ============================
    methods (Access = protected)
        function obj = HasOptions(options)
            % Initialize an options-dependent object.
            obj.options = options;
        end
    end
    
end
