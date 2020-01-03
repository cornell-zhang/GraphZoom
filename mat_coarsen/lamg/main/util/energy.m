function e = energy(problem, x)
%ENERGY Energy norm.
%   E=ENERGY(PROBLEM,X) computes the energy of a vector X for the problem
%   PROBLEM.
%
%   See also: PROBLEM, LPNORM.

e = x'*(problem.A*x);

end
