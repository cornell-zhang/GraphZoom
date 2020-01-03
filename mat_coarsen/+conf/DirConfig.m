classdef (Sealed) DirConfig < handle
    %DIRCONFIG make script configuration for a single path.
    %   This class holds the MAKE configuration script for a single path
    %   under the main path where MAKE is being invoked.
    %
    %   See also: MAKE, MAKECONFIG.
    
    %======================== MEMBERS =================================
    properties (GetAccess = public, SetAccess = private)
        dir         % Directory path
        type        % Type of directory: 'required', 'optional' or 'parent'
    end
    properties (Dependent)
        addToPath   % Add this directory to the MATLAB path or not
    end
    
    %======================== CONSTRUCTORS ============================
    methods
        function obj = DirConfig(home, dir, type)
            % Build a make configuration structure from the init file
            % INITFILE.
            obj.dir = [home '/' dir];
            obj.type = type;
        end
    end
    
    %======================== METHODS =================================
    methods
        
    end
    
    %======================== GET & SET ===============================
    methods
        function flag = get.addToPath(obj)
            % Add this directory to the MATLAB path or not
            flag = ~strcmp(obj.type, 'parent');
        end
    end
    
    %======================== PRIVATE METHODS =========================
end