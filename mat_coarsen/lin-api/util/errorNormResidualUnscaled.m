function e = errorNormResidualUnscaled(dummy1, dummy2, r, dummy3, dummy4) %#ok
%ERRORNORMRESIDUAL Error norm of an approximate solution.
%   E=ERRORNORMRESIDUALUNSCALED(PROBLEM,X) computes the standard L2
%   residual norm of an approximate solution X of the problem PROBLEM.
%
%   See also: PROBLEM, LPNORM.

%e = norm(problem.b - problem.A*x);
e = norm(r);

end
