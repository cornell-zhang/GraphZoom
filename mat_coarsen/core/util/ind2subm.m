function f = ind2subm(siz,a)
%IND2SUBM Multiple subscripts in matrix-form from linear index.
%   IND2SUBM is used to determine the equivalent subscript values
%   corresponding to a given single index into an array.
%
%   F = IND2SUB(SIZ,IND) returns a matrix of size SIZE(SIZ,1)xLENGTH(IND),
%   containing the equivalent N-D array subscripts equivalent to IND for an array
%   of size SIZ. It behaves like IND2SUB, except that the input is not an
%   argument list (a cell array), but a matrix.
%
%   See also IND2SUB, SUB2IND, FIND.
 
% Author: Oren Livne
% Date  : 06/23/2004    Added comments.

if (isempty(a))
    f = [];
    return;
end

if (size(a,2) > 1)
    a = a';
end
dim                 = length(siz);
f                   = cell(dim,1);
[f{1:dim}]          = ind2sub(siz,a);
f                   = cat(2,f{:});
f                   = sortrows(f,[dim:-1:1]);
