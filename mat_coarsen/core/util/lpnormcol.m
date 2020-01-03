function res = lpnormcol(x,p)
%LPNORMCOL Scaled Lp norm applied to columns.
%   Y=LPNORMCOL(X,p) gives the scaled Lp norm of a vector, that is, Y =
%   (sum(abs(X).^p)/length(X))^(1/p). LPNORM(X) returns the L2 norm of the
%   vector.
%
%   If X is a matrix, Y=LPNORMCOL(X,p) returns the vector of Lp norms of
%   the columns of X.
%
%   See also: NORM.

if (nargin < 2)
    p = 2;
end

if (strcmp(p, 'inf'))
    res = max(abs(x));
else
    res = (sum(abs(x).^p)/size(x,1)).^(1/p);
end
