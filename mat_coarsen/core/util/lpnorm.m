function res = lpnorm(x,p)
%LPNORM Scaled Lp norm.
%   Y=LPNORM(X,p) gives the scaled Lp norm of a vector, that is,
%   Y = (sum(abs(X).^p)/length(X))^(1/p). LPNORM(X) returns the
%   L2 norm of the vector.
%
%   If X is a matrix, Y=LPNORM(X,p) returns the vector of Lp norms of the
%   columns of X.
%
%   See also: NORM.

if (isempty(x))
    res = 0;
else
    if (nargin < 2)
        p = 2;
    end
    
    if (strcmp(p, 'inf'))
        res = max(abs(x(:)));
    else
        res = (sum(abs(x(:)).^p)/length(x(:))).^(1/p);
    end
end