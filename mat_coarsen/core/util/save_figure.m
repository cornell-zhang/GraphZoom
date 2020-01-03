function save_figure(type, relativeFileName, varargin)
%SAVE_FIGURE A utility to save the current figure to file.
%   Assumes that the OUTPUT_DIR global variable has been set.
%
%   Examples:
%       Save the current figure to a color EPS file named 'a_b.eps' under
%       OUTPUT_DIR:
%       save_figure('epsc', '%s_%s.eps', 'a', 'b');
%
%   See also: PRINT.

% Define global variables
global GLOBAL_VARS           % Results output directory

fileName = strcat(GLOBAL_VARS.out_dir, '/', sprintf(relativeFileName, varargin{:}));
create_dir(fileName, 'file');
eval(sprintf('print -d%s %s', type, fileName));
