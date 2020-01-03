classdef (Sealed) MakeConfig < handle
    %MAKECONFIG global make script configuration.
    %   This class holds the main build configuration used by the MAKE
    %   script.
    %
    %   See also: MAKE, DIRconf.
    
    %======================== MEMBERS =================================
    properties (GetAccess = public, SetAccess = private)
        dirConfigs    % A map of path to DirConfig object
    end
    
    %======================== CONSTRUCTORS ============================
    methods
        function obj = MakeConfig(home, initFile)
            % Build a make configuration structure for using current
            % directory HOME from the init file HOME/INITFILE.
            
            initFilePath = [home '/' initFile];
            if (exist(initFilePath, 'file'))
                % Parse file
                fid = fopen(initFilePath, 'r');
                data = textscan(fid, '%s%s');
                fclose(fid);
                data = cell2struct(data, {'dir', 'type'}, 2);
            else
                data = struct('dir', [], 'type', []);
            end
            
            % Create config entries for each path
            obj.dirConfigs = containers.Map();
            for i = 1:numel(data.dir)
                dir = data.dir{i};
                dirConfig = conf.DirConfig(home, dir, data.type{i});
                obj.dirConfigs(dir) = dirConfig;
            end
            
            % If current directory doesn't exist in build list, add it with
            % default parameters
            if (~obj.dirConfigs.isKey('.'))
                dirConfig = conf.DirConfig(home, '.', 'parent');
                obj.dirConfigs('.') = dirConfig;
            end
        end
    end
    
    %======================== METHODS =================================
    methods
        function configs = nestedDirConfigs(obj)
            % Return all configs except the current directory's.
            keys = sort(setdiff(obj.dirConfigs.keys, '.'));
            configs = containers.Map();
            for i = 1:numel(keys)
                key = keys{i};
                configs(key) = obj.dirConfigs(key);
            end
        end
    end
    
    %======================== PRIVATE METHODS =========================
end