function e = errorNormL2(dummy1, x, dummy2, dummy3, dummy4) %#ok
%ERRORNORML2 L2 error norm.
%   E=ERRORNORML2(PROBLEM,X) computes the scaled L2 norm of an approximate
%   solution X of the problem PROBLEM, assuming that the RHS is 0 (i.e. X
%   is an error vector).
%
%   See also: PROBLEM, LPNORM.

e = lpnorm(x);

end
