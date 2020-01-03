function [x, fval, exitflag] = linfmin(A, b, options)
%LINFMIN L-infinity norm minimization.
%   X=LINFMIN(A,B) returns the solution of the minimization problem MIN
%   |A*X-B|, where |.| is the maximum norm. The problem is transformed to a
%   linear programming problem. This function requires the MATLAB
%   Optimization Toolbox.
%
%   See also: LINPROG.

if (nargin < 3)
    options = optimset;
end

% Transform the problem to min e^T*z s.t. z >= A*x-b, z >= -(A*x-b)
[m,n]   = size(A);
f       = [ zeros(n,1); 1 ];
Ane     = [ +A, -ones(m,1) ; -A, -ones(m,1) ];
bne     = [ +b; -b ];

% Solve
[xt, fval, exitflag] = linprog(f,Ane,bne,[],[],[],[],[],options);

% Recover the original variables
x       = xt(1:n,:);
end
