function e = errorNormResidual(dummy1, dummy2, r, dummy3, dummy4) %#ok
%ERRORNORMRESIDUAL Error norm of an approximate solution.
%   E=ERRORNORMRESIDUAL(PROBLEM,X) computes the scaled L2 residual norm of an
%   approximate solution X of the problem PROBLEM.
%
%   See also: PROBLEM, LPNORM.

%e = lpnorm(problem.b - problem.A*x);
e = lpnorm(r);

end
