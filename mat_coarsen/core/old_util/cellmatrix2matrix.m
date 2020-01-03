function u = cellmatrix2matrix(ucell)
%CELLMATRIX2MATRIX  Convert a cell matrix to a matrix.
%   This script converts a cell array ucell of 2D functions into a 2D
%   matrix u. Each column of u is the 1D "unwrapped" version of a 2D
%   function in ucell.
%
%   Input:
%   ucell = a cell array ucell of 2D functions.
%   Output:
%   u = matrix with the 1D "unwrapped" functions.
%
%    See also FIND_VAR.

% Revision history:
% 05/30/2004    Oren Livne      Added comments.

m = length(ucell);
u = [];
for k = 1:m,
    u = [u ucell{k}(:)];
end
