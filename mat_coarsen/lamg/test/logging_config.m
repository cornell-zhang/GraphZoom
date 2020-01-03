function [root, logger] = logging_config
%LOGGING_CONFIG Logging configuration.
%   Acts as log4j.properties' MATLAB counterpart. Set logger properties
%   here. Loggers inherit and override their parents' properties.

import core.logging.*;

% The root logger. Assumes that no package called "root" is on the path.
% The line printout format may be specified, followed by arguments.
% "level", "message" are interpreted literally; all other arguments are
% assumed to be Logger field names.
logger                              = containers.Map;
root                                = struct;
root.lineFormat                     = {'%s', 'message'};
%root.lineFormat = {'%-5s  %-10s  %s', 'level', 'simpleName', 'message'};  % Line printout format (up to formatted string), followed by arguments. "level", "message" are interpreted literally; all other arguments are assumed to be Logger field names.

root.level                          = 'WARN'; %'DEBUG';
%logger('lin.api')                   = 'INFO'; %'DEBUG';
%logger('amg')                      = 'DEBUG';
%logger('graph')                    = 'DEBUG';
