function x1 = secant(func,x0,x1,max_iter,verbose)
%SECANT  Scalar nonlinear zero finding using the Secant method.
%   X = FZERO(FUN,X0,X1,VERBISE) tries to find a zero of the function FUN near
%   X0,X1 (two initial guesses are required for the Secant method). VERBOSE
%   generates some inputs if specified as 1 [default = 0].
%   FUN accepts real scalar input X and returns a real scalar function value F 
%   evaluated at X.  The value X returned by SECANT is near a point where FUN 
%   changes sign (if FUN is continuous). FUN can be specified using @,
%   e.g.: X = fzero(@sin,3) returns pi.
%
%   See also  FMINBND, FZERO, INLINE, ROOTS, @.

% Revision history:
% 05/30/2004    Oren Livne    Created.

if (nargin < 4)
    max_iter = 30;
end
if (nargin < 5)
    verbose = 0;
end

f0     = func(x0);
f1     = func(x1);
if (verbose)
    fprintf('Secant root search\n');
    fprintf('Iter.          x                      f\n');
    fprintf('%2d   %+.16f   %+.16e\n',0,x0,f0);
    fprintf('%2d   %+.16f   %+.16e\n',1,x1,f1);
end
iter    = 1;
while ((abs(f1) > 1e-15) && (iter <= max_iter))                     % Stopping criterion: |F(x)| < 1e-15 or max. iter reached
    iter    = iter+1;
    x2      = x1 - f1*(x1-x0)/(f1-f0);                              % Secant step for x
    f2      = func(x2);
    f0      = f1; x0 = x1;
    f1      = f2; x1 = x2;
    if (verbose)
        fprintf('%2d   %+.16f   %+.16e\n',1,x1,f1);
    end
end
