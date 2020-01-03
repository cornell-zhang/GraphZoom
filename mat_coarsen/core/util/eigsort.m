function [v, lam, d] = eigsort(A, mode)
%EIGSORT returns the sorted eigenvalues of a matrix.
%   [V,LAM,D]=EIGSORT(A,MODE) returns the sorted eigenpairs (V,LAM) of A
%   and LAM's magnitudes in the vector D. LAM is also a vector.
%
%    MODE selects the direction of the sort
%       'ascend' results in ascending order.
%       'descend' results in descending order.
%
%   See also: EIG.

[v,d]   = eig(full(A));
lam     = diag(d);
d       = abs(lam);
[dummy,i]   = sort(d,1,mode); %#ok
clear dummy;
d       = d(i);
v       = v(:,i);
lam     = lam(i);
