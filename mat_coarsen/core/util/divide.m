function c = divide(a,b)
%DIVIDE Integer division into almost-even parts.
%   C = DIVIDE(A,B) divides A cells into C patches, each of size B,
%   possibly except the last patch, whose size is in the range [B/2,3*B/2).
%   A,B can be vectors of size d (C will have the same size). C is simply
%   the number of patches in each direction.
%
%   See also CEIL.
 
% Author: Oren Livne
% Date  : 06/23/2004    Version 1: created.

c           = ceil(a./b);
small       = find((rem(a,b) < b/2) & (rem(a,b) > 0));
c(small)    = c(small)-1;
