function e = errorNormL2Difference(dummy, x, xOld) %#ok
%ERRORNORML2 L2 error norm of iterate difference.
%   E=ERRORNORML2(PROBLEM,X,XOLD) computes the scaled L2 norm of X-XOLD.
%   This works for non-homogeneous problems.
%
%   See also: PROBLEM, LPNORM.

e = lpnorm(x-xOld);

end
