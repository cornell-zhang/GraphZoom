function Problem = ufget (matrix, UF_Index, action)
%UFGET loads a matrix from the UF Sparse Matrix Collection.
%
%   Problem = ufget(matrix) loads a matrix from the uf sparse matrix collection,
%   specified as either a number (1 to the # of matrices in the collection) or
%   as a string (the name of the matrix).  With no input parameters, index=ufget
%   returns an index of matrices in the collection.  A local copy of the matrix
%   is saved.  If no input or output arguments are provided, the index is
%   printed.  With a 2nd parameter (Problem = ufget (matrix, index)), the index
%   file is not loaded.  This is faster if you are loading lots of matrices.
%
%   Examples:
%       index = ufget ;                     % loads index
%       index = ufget ('refresh') ;         % forces download of new index
%       index = ufget ('update') ;          % same as 'refresh'
%
%       Problem = ufget (6)                 % 4 ways of loading the same Problem
%       Problem = ufget ('HB/arc130')
%       Problem = ufget (6, index)
%       Problem = ufget ('HB/arc130', index)
%
%       Problem = ufget (6, index, 'download') % forces problem file download without loading in into MATLAB
%
%   See also ufgrep, ufweb, ufget_example, ufget_defaults, urlwrite.

%   Copyright 2009, Tim Davis, University of Florida.

%-------------------------------------------------------------------------------
% get the parameter settings
%-------------------------------------------------------------------------------

params = ufget_defaults ;

% Synchronize UF directory with Oren's global config params facility
config;
global GLOBAL_VARS
params.dir = [GLOBAL_VARS.data_dir '/uf/mat/'];
params.topdir = [GLOBAL_VARS.data_dir '/uf'];

% The UF_Index.mat file is used by ufget only, not by ufgui.java.
indexfile = sprintf ('%sUF_Index.mat', params.dir) ;
indexurl  = sprintf ('%s/UF_Index.mat', params.url) ;

% The ufstats.csv file is used by the ufgui.java program.  It is also used by
% the ufkinds.m function, which reads the file to find the problem kind for
% each matrix in the collection.
statfile = sprintf ('%smatrices/UFstats.csv', params.topdir) ;
staturl  = sprintf ('%s/matrices/UFstats.csv', params.topurl) ;

%-------------------------------------------------------------------------------
% get the index file (download a new one if necessary)
%-------------------------------------------------------------------------------

download_only = false;
if (nargin >= 3)
    if (ischar(action))
        if (strcmp(action, 'download'))
            download_only = true;
        else
            error('Unrecognized third argument ''%s''', action);
        end
    end
end

refresh = 0 ;
if nargin == 0
    % if the user passed in a zero or no argument at all, return the index file
    matrix = 0 ;
elseif (download_only)
    % User passed in matrix and download flag
    refresh = 1;
else
    % ufget ('refresh') downloads the latest index file from the web
    if (ischar (matrix))
        if (strcmp (matrix, 'refresh') || strcmp (matrix, 'update'))
            matrix = 0 ;
            refresh = 1 ;
        end
    end
end

if (~refresh)
    try
        % load the existing index file
        if (nargin < 2)
            load (indexfile) ;
        end
        % see if the index file is old; if so, download a fresh copy
        fileinfo = dir (indexfile) ;
        refresh = (fileinfo.datenum + params.refresh < now) ;
    catch e %#ok
        % oops, no index file, or a refresh is due.  download it.
        refresh = 1 ;
    end
end

err = '' ;      % to catch a download error, if any

if (refresh)
    % a new UF_Index.mat file to get access to new matrices (if any)
    try
        if (~exist (params.dir, 'dir'))
            mkdir (params.dir) ;
        end
        
        % get a new UF_Index.mat file
        tmp = tempFileName ;                        % download to a temp file first
        old = sprintf ('%sUF_Index_old.mat', params.dir) ;
        urlwrite (indexurl, tmp) ;              % download the latest index file
        try
            movefile (indexfile, old, 'f') ;    % keep a backup of the old index
        catch e %#ok
            % backup failed, continue anyway
        end
        movefile (tmp, indexfile, 'f') ;        % move the new index into place
        
        % get a new ufstats.csv file
        tmp = tempFileName ;                        % download to a temp file first
        old = sprintf ('%smatrices/UFstats_old.csv', params.topdir) ;
        urlwrite (staturl, tmp) ;               % download the latest stats file
        try
            movefile (statfile, old, 'f') ;     % keep a backup of the old stats
        catch e %#ok
            % backup failed, continue anyway
        end
        movefile (tmp, statfile, 'f') ;         % move the new index into place
        
    catch e
        err = e;
    end
    load (indexfile) ;
    UF_Index.DownloadTimeStamp = now ;
    save (indexfile, 'UF_Index') ;
end

%-------------------------------------------------------------------------------
% return the index file if requested
%-------------------------------------------------------------------------------

if (matrix == 0)
    if (nargout == 0)
        % no output arguments have been passed, so print the index file
        fprintf ('\nuf sparse matrix collection index:  %s\n', ...
            UF_Index.LastRevisionDate) ;
        fprintf ('\nLegend:\n') ;
        fprintf ('(p,n)sym:  symmetry of the pattern and values\n') ;
        fprintf ('           (0 = unsymmetric, 1 = symmetric, - = not computed)\n') ;
        fprintf ('type:      real\n') ;
        fprintf ('           complex\n') ;
        fprintf ('           binary:  all entries are 0 or 1\n') ;
        nmat = length (UF_Index.nrows) ;
        for j = 1:nmat
            if (mod (j, 25) == 1)
                fprintf ('\n') ;
                fprintf ('ID   Group/Name                nrows-by-  ncols  nonzeros  (p,n)sym  type\n') ;
            end
            s = sprintf ('%s/%s', UF_Index.Group {j}, UF_Index.Name {j}) ;
            fprintf ('%4d %-30s %7d-by-%7d %9d ', ...
                j, s, UF_Index.nrows (j), UF_Index.ncols (j), UF_Index.nnz (j)) ;
            psym = UF_Index.pattern_symmetry (j) ;
            nsym = UF_Index.numerical_symmetry (j) ;
            if (psym < 0)
                fprintf ('  -  ') ;
            else
                fprintf (' %4.2f', psym) ;
            end
            if (nsym < 0)
                fprintf ('  -  ') ;
            else
                fprintf (' %4.2f', nsym) ;
            end
            if (UF_Index.isBinary (j))
                fprintf (' binary\n') ;
            elseif (~UF_Index.isReal (j))
                fprintf (' complex\n') ;
            else
                fprintf (' real\n') ;
            end
        end
    else
        Problem = UF_Index ;
    end
    
    if (~isempty (err))
        fprintf ('\nufget: unable to download latest index; using old one.\n') ;
        disp (err) ;
    end
    return ;
end

%-------------------------------------------------------------------------------
% determine if the matrix parameter is a matrix index or name
%-------------------------------------------------------------------------------

[group matrix id] = ufget_lookup (matrix, UF_Index) ;

if (id == 0)
    error ('invalid matrix') ;
end

%-------------------------------------------------------------------------------
% download the matrix (if needed) and load it into MATLAB

matdir = sprintf ('%s%s%s%s.mat', params.dir, group) ;
matfile = sprintf ('%s%s%s.mat', matdir, filesep, matrix) ;
maturl = sprintf ('%s/%s/%s.mat', params.url, group, matrix) ;

if (~exist (matdir, 'dir'))
    mkdir (matdir) ;                        % create the Group directory
end

if (download_only || ~exist (matfile, 'file'))
    fprintf ('downloading %s\n', maturl) ;
    fprintf ('to %s\n', matfile) ;
    tmp = tempFileName ;                        % download to a temp file first
    urlwrite (maturl, tmp) ;
    movefile (tmp, matfile, 'f') ;          % move the new matrix into place
    %    urlwrite(maturl, matfile);
end

if (download_only)
    Problem = [];
else
    load (matfile) ;
end
end

%----------------------------------------------------------
% Generate a temporary file name in a directory we control.
function file= tempFileName()
file = tempname;
%  dir = '/lustre/beagle/lamg/jobs/tmp';
%  if (~exist(dir, 'dir'))
%    mkdir(dir);
%  end
%  file = [dir '/ufgettmp' sprintf('%s', randi(1e6,1,1))];
end
