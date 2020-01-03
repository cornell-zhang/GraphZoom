%UFGET_EXAMPLE a demo for ufget.
%   This example script gets the index file of the UF sparse matrix collection,
%   and then loads in all symmetric non-binary matrices, in increasing order of
%   number of rows in the matrix.
%
%   Example:
%       type ufget_example ; % to see an example of how to use ufget
%
%   See also ufget, ufweb, ufgrep.

%   Copyright 2009, Tim Davis, University of Florida.

type ufget_example ;

index = ufget ;
f = 1:numel(index.nrows);
%f = find(strcmp(index.Group, 'SNAP'))';
%f = find (index.numerical_symmetry == 1 & ~index.isBinary) ;
[y, j] = sort (index.nrows (f)) ;
f = f (j) ;

j = 2548; %0;
n = numel(f);
for i = f(2549:end)
j = j+1;
    fprintf ('[%d/%d] Loading %s%s%s, please wait ...\n', ...
        j, n, index.Group {i}, filesep, index.Name {i}) ; 
    Problem = ufget (i,index,'download') ;
%    Problem = ufget (i,index) ;
%    disp (Problem) ;
    % spy (Problem.A) ;
    % title (sprintf ('%s:%s', Problem.name, Problem.title')) ;
    %    ufweb (i) ;
    %    input ('hit enter to continue:') ;
    
    clear Problem; % Save on memory
end

