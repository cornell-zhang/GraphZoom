function r = newton(f,df,x,niter,tol)
%
% NEWTON(f,df,x,niter,tol) basic implementation of Newton's method to find
% a root of f
%
% input:
%   f       string giving function (e.g.,  'sin(x^3)+3*x-5') df      string
%   giving derivative x       initial value for iteration niter   maximum
%   number of iterations tol     tolerance
%
% output:
%   r       approximate root
%
% We use a simple stopping criteria: the iterates change by at most tol, or
% niter iterations made.
%
% If tol is not given, 0 is used, meaning that the root is to be found to
% machine precision.  If neither tol nor niter is given, 0 is used for tol
% and 100 for niter.
%
% Douglas N. Arnold, September 1997

% check for 3, 4, or 4 arguments, set tol and niter if nedessary
if (nargin == 3)
    niter = 100; tol = 0;
elseif (nargin == 4)
    tol = 0;
elseif (nargin ~= 5)
    fprintf('\nUsage: r = newton0(f,df,x,niter,tol)\n');
    return
end

% display header and input data
fprintf('\neval                    x          f(x)\n');
fprintf(  '----    -----------------   -----------\n');
count = 0;

for iter = 1:niter
    % evaluate f and f'
    num = f(x);
    den = df(x);
    count = count + 1;
    fprintf(  '%4d   %18.16g %13.6g\n',count,x,num);
    delx = num/den;
    x = x - delx;
    if (abs(delx) <= tol)
        fprintf('\ntolerance achieved\n');
        r = x;
        fprintf(  'root: %18.16g\n',r);
        return
    end
end

fprintf('maximum number of iterations reached\n');
r = x;
fprintf(  'root: %18.16g\n',r);
