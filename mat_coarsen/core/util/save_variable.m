function save_variable(var, type, relativeFileName, varargin)
%SAVE_VARIABLE A utility to save a variable to a file.
%   Assumes that the OUTPUT_DIR global variable has been set.
%   
%   Examples:
%       Save the workspace variable x to an ascii file named 'a_b.txt' under
%       OUTPUT_DIR:
%       x = 1:10;
%       save_variable(x, 'ascii', '%s_%s.txt', 'a', 'b');
%
%   See also: SAVE.

% Define global variables
global OUTPUT_DIR           % Results output directory

fileName = strcat(OUTPUT_DIR, '/', sprintf(relativeFileName, varargin{:}));
create_dir(fileName, 'file');
eval(sprintf('save %s var -%s', fileName, type));
