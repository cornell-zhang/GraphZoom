function e = errorNormResidualRelative(problem, x, dummy) %#ok
%errorNormResidualRelative Error norm of an approximate solution.
%   E=errorNormResidualRelative(PROBLEM,X) computes norm(A*x-b)/norm(b)
%   for an approximate solution X of the problem PROBLEM.
%
%   See also: PROBLEM, LPNORM.

e = norm(problem.b - problem.A*x)/norm(problem.b);

end
