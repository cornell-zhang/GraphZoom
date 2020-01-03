function M = twoLevelOperator(setup, nu, g)
%TWOLEVELOPERATOR Two-level AMG error propagation matrix.
%   Returns the actual two-level propagator of levels SETUP{1} and
%   SETUP{2}. M=TWOLEVELOPERATOR(NU,G) returns the propagator for a (NU,0)
%   two-level cycle with RHS correction matrix G. M=TWOLEVELOPERATOR(NU)
%   uses G = identity.
%
%   See also: SETUP, MULTILEVELSETUP.

% Read and set input arguments
if (nargin < 3)
    g = 1; % No energy correction
end

% Load levels
f           = 1;
c           = 2;
fineLevel   = setup.level{f};
coarseLevel = setup.level{c};
n           = fineLevel.size;

% Compute 2-level operator
nc          = coarseLevel.size;
y           = spones(ones(nc,1));
Ac          = [[coarseLevel.A y]; [y' 0]];
Bc          = inv(Ac);
Bc          = Bc(1:nc,1:nc);

% Energy correction matrix
G           = repmat(g, n, 1);
G(1)        = 1.;
G(end)      = 1.;
G           = spdiags(G, 0, n, n);

% Compute two-level operator M
C   = speye(fineLevel.size) - coarseLevel.P * Bc * coarseLevel.R * G * fineLevel.A;
R   = fineLevel.relaxMatrix;
M   = R^nu*C;

% Simulate post-subtracting the iterate x's mean from x
y = spones(ones(n,1));
B = speye(n) - y*y'/(y'*y);
M = B*M;

end
