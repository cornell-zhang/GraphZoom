function create_dir(path, type, verbose)
%CREATE_DIR Create a directory if it does not exist yet.
%
%   Examples:
%       Create a directory (and all its ancestors):
%       create_dir('c:/a/b') creates the directory c:/a/b
%       create_dir('c:/a/b', 'dir') creates the directory c:/a/b
%
%       Create the parent directory (and all its ancestors) required for a
%       file name path: create_dir('c:/a/b/c.png', 'file') creates the
%       directory c:/a/b
%
%   See also: MKDIR, REGEXP.

% Global variables
split_str = '/';

% Read input arguments, set default
if (nargin < 2)
    type = 'dir';
end
if (nargin < 3)
    verbose = false;
end

% Decide whether to create the last part of the tokenized path as a
% directory or ignore it because it's the file part of a file path
switch (type)
    case 'dir'
        last = 0;
    case 'file'
        last = 1;
    otherwise
        error('MATLAB:CREATE_DIR:InputArg','Path type must be ''dir'' or ''file''');
end

% Tokenize the input path
parts = regexp(path, split_str, 'split');

% Walk the directory hierarchy and create directories if needed
dir = '';
for i = 1:length(parts)-last
    if (i == 1)
        dir = parts{1};
    else
        dir = strcat(dir, split_str, parts{i});
    end
    if (~isempty(dir) && ~exist(dir, 'dir'))
        if (verbose)
            fprintf('Directory ''%s'' does not exist, creating\n', dir);
        end
        mkdir(dir);
    end
end
