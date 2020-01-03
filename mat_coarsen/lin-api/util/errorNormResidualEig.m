function e = errorNormResidualEig(problem, y, dummy) %#ok
%ERRORNORMRESIDUAL Eigenvalue residual norm.
%   E=ERRORNORMRESIDUAL(PROBLEM,Y) computes the scaled L2 eigenvalue
%   residual norm of an approximate solution Y=[X;LAMBDA] of the eigenvalue
%   problem PROBLEM (A*X=LAMBDA*B*X).
%
%   See also: PROBLEM, LPNORM.

x = y.x;
e = lpnorm(problem.A*x - y.lam*problem.B*x);

end
