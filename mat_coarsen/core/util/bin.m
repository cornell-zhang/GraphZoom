function [C,f,avg_c] = bin(A,p,max_iter,verbose,x)
% BIN    Binormalization of a real symmetric matrix A.
%
%    We use the BIN algorithm, which is based on the average binormalization
%    equations. This is a stand-alone module (doesn't depend on l).
%
%    Input:
%    A = nxn matrix
%    p        = normalize the Lp-norm of the A-rows to 1. Default: p=1
%    max_iter = maximum number of sweeps (default = 10)
%    verbose  = verbose mode flag (0=no printout, default; 1=printouts;
%               2=Latex-formatted printouts)
%    x        = (x1,...,xn),initial condition for fi^2. Default: all xi = 1
%
%    Output:
%    C     = The normalized matrix C = F*A*F
%    f     = The scaling factors f = (f1...fn); F = diag(f) in
%            the previous line.
%    avg_c = average convergence factor of the residuals of
%            the binormalization equations.

% Revision history:
% 06/16/03    Oren Livne    Created
% 06/17/03    Oren Livne    Added p to parameters; removed unnecessary nargouts

global fout;
% Define parameters
n                = size(A,1);
if (nargin < 2)
    p            = 1;           % Lp norm of A-rows is normalized to 1.
end
if (nargin < 3)
    max_iter     = 10;
end
if (nargin < 4)
    verbose      = 0;
end
if (nargin < 5)
    x            = ones(n,1);   % initial guess; x(i) = f(i)^2.
end
TOL              = 1e-10;       % stopping criterion based on residuals

% Initializations
B                = abs(A).^p;
d                = diag(B);
beta             = B*x;
avg              = x'*beta/n;
step             = 0;
e                = 1.;
std              = full(sqrt(sum((x.*beta-avg).^2)/n))/avg;
step             = step+1;
std_initial      = std;
conv_factor      = 0;

if (verbose)
    fprintf('BINORMALIZATION');
    fprintf('Sweep        STD       RATE        DIFF-X     RATE\n');
    fprintf('INITIAL   %.3e\n',std);
end

% The main loop over BIN sweeps
for r = 1:max_iter
    x_old = x;
    
    % Reached Below tolerance ==> break
    if (std < TOL)
        break;
    end
    
    % step over all variables i=1,...,n and update each by turn
    % (Gauss Seidel)
    for i = 1:n,
        % Solve quadratic equation for the updated x(i) (denoted xi)
        bi  = beta(i);
        di  = d(i);
        xi  = x(i);
        c2  = (n-1)*di;
        c1  = (n-2)*(bi-di*xi);
        c0  = -di*xi^2 + 2*bi*xi - n*avg;
        if (-c0 < eps)
            if (verbose)
                out(1,'Matrix nearly unscalable: row %d, c0=%f\n',i,c0);
            end
            C = A;
            f = ones(n,1);
            avg_c = -1;
            G = -1;
            est_c = -1;
            return;
        else
            xi = (2*c0)/(-c1 - sqrt(c1*c1 - 4*c2*c0));
        end
        
        % Update the auxiliary variables accordingly
        delta    = xi - x(i);                      % xi_new - xi_old
        avg      = avg   + (delta*x'*B(:,i) + delta*bi + di*delta^2)/n;
        beta    = beta + delta*B(:,i);
        x(i)     = xi;
    end
    % Compute and print the convergence statistics
    std_old = std;
    e_old   = e;
    std     = full(sqrt(sum((x.*beta-avg).^2)/n))/avg;
    e       = norm(x-x_old)/norm(x);
    conv_factor  = std/std_old;
    if (verbose)
        fprintf('%3d       %.3e   %.3f      %.3e   %.3f\n',...
            r,std,conv_factor,e,e/e_old);
    end
end

% Print convergence factor and display err if desired
if (std_initial < eps)
    avg_c = 0;
else
    avg_c = (std/std_initial)^(1/r);
end
if (verbose)
    fprintf('BIN: #Iterations = %3d    std_row = %.3e     conv_factor = %.3f\n',...
        r,std,avg_c);
end

% Finalize by computing f from x and scaling everything to 2-norm=1
f        = sqrt(x);
F        = spdiags(f,0,n,n);
C        = F*A*F;
beta     = sum(abs(C).^p)';
avg      = full(sum(beta)/n);
norm_c   = avg^(1/p);
C        = C*(1./norm_c);
f        = f*(1./sqrt(norm_c));
