function e = rayleighQuotient(problem, x)
%RAYLEIGHQUOTIENT Rayleigh quotient.
%   E=RAYLEIGHQUOTIENT(PROBLEM,X) computes the Rayleigh Quotient
%   X'*A*X/(X'*X) of a vector X for the eigenproblem PROBLEM. If X is a matrix,
%   E is the vector of RQs of the columns of X.
%
%   See also: PROBLEM, LPNORM.

e = sum(x.*(problem.A*x)) ./ sum(x.*x);

end
