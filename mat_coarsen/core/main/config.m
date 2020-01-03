function config(fileName)
%CONFIG Set up the entire environment configuration.
%   CONFIG(FILENAME) loads logging, and loads environment variable configuration
%   from file FILENAME.
%
%   If no FILENAME is specified, 'config_ENV.txt' is used by default, where
%   ENV is the value of the environment variable 'MATLAB_PROFILE'.
%
%   See also: LOAD_CONFIG, LOGGING_CONFIG.

% Read inputs
env = getenv('MATLAB_PROFILE');
if (nargin < 1)
    if (isempty(env))
        fileName = 'config.txt';
    else
        fileName = ['config_' env '.txt'];
    end
end

% Define global variables
global GLOBAL_VARS
if (isempty(GLOBAL_VARS))
    GLOBAL_VARS = load_config(fileName);
end

% Logging
logging_config;

% Email
if (~isdeployed)
    email_config;
end

end
