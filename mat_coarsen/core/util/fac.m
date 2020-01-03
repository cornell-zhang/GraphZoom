function res = fac(a)
%FAC Relative factors.
%   RES = FAC(A) returns the relative factors (like DIFF, but
%   multiplicative - the ratio of each two conseuqetive elements of A).
%   This is useful for measuring algebraic convergence.

% Revision history:
% 05/30/2004    Oren Livne      Created.

a(a < eps) = eps;
res = exp(diff(-log(a)));
