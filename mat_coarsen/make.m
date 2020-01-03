function make(varargin)
%MAKE LAMG MATLAB code installation script.
%   MAKE(COMPILE) compiles mex files and adds directories to the path.
%   MAKE() is synonymous with MAKE(FALSE).

goals = varargin;
home = currentPath();

% Read dependencies file with list of relative paths to make in
makeConfig = conf.MakeConfig(home, 'make.ini');

% Make in the current directory
makeInPath(makeConfig.dirConfigs('.'), home, goals);

% Recursively make in all paths we depend on
for d = makeConfig.nestedDirConfigs.values
    dirConfig   = d{:};
    dir         = dirConfig.dir;
    pathExists  = (exist(dir, 'dir') == 7);
    if (~pathExists && strcmp(dirConfig.type, 'optional'))
        % Ignore inexistent optional dir
        continue;
    end
    
    eval(sprintf('cd %s', dirConfig.dir));
    if (dirConfig.addToPath)
        addpath(pwd);
    end
    e = [];
    try
    make(goals{:}, 'nested');
    catch ex
        e = ex;
    end
    % Finally clause: return to home directory
    eval(sprintf('cd %s', home));
    if (~isempty(e))
        throw(e);
    end
end

if (~ismember('nested', goals))
  % Do at top level only
    if (ismember('local-path', goals))
    % Save path locally
    savepath pathdef.m;
  else
    % Save path globally
    savepath;
  end
end
fprintf('Make successful in %s\n', home);
end

%------------------------------------------------------------------------
function makeInPath(dirConfig, home, goals)
% Make the goals GOALS in the directory specified by DIRCONF under the HOME
% directory.
compile = ismember('compile', goals);
dir     = dirConfig.dir;
pathExists = (exist(dir, 'dir') == 7);
if (pathExists)
    e = [];
    try
        fprintf('Making in %s\n', dir);
        eval(sprintf('cd %s', dir));
        if (dirConfig.addToPath)
            addpath(pwd);
        end
        
        if (compile)
            mexFile = [pwd '/makemex.ini'];
            if (exist(sprintf('%s/makethis.m', pwd), 'file') == 2)
                % Found custom make config, run it
                fprintf('Running custom make in %s\n', dir);
                eval(sprintf('run %s/makethis', pwd));
            elseif (exist(mexFile, 'file'))
                % Found mex config, make mex files
                fprintf('Making mex files in %s\n', dir);
                fid = fopen(mexFile, 'r');
                mexFiles = textscan(fid, '%s');
                fclose(fid);
                cellfun(@(x)(eval(sprintf('mex -O -largeArrayDims %s', x))), mexFiles{1});
            end
        end
    catch ex
        e = ex;
    end
    % Finally clause: return to home directory
    eval(sprintf('cd %s', home));
    if (~isempty(e))
        throw(e);
    end
else
    if (strcmp(type, 'required'))
        error('Did not required find path %s\n', dir);
    else
        fprintf('Did not find path %s\n', dir);
    end
end
end

%------------------------------------------------------------------------
% Get normalized current directory path.
function path = currentPath()
path = strrep(pwd, '\', '/');
end
