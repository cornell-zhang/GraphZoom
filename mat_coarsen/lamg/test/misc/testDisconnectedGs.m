function testDisconnectedGs(n, e)
%TESTDISCONNECTEDGS GS asymptotic behavior for a nearly-disconnected graph.
%   We construct a 1-D grid graph that consists of two nearly-disconnected
%   sub-domains. All connection strengths within each subdomain is 1, and
%   the inter-sub-domain connection strength is E.
%
%   We study the GS iteration matrix eigenvalues and eigenvectors as a
%   function of E. The ACF turns out to be ~ 1-O(E).

if (nargin < 1)
    n = 6;      % Graph size
end
if (nargin < 2)
    e = 1e-4;   % Disconnection measure
end

[A, v, d, lambda, acf] = gsSpectrum(n, e); %#ok
% lambda'
% v
% normOfColumns(A*v)
fprintf('ACF = %s\n', formatAcf(acf));
end

%--------------------------------------------------------------------------
function [A, v, d, lambda, acf] = gsSpectrum(n, e)
% Compute the GS spectrum for a path graph of size N with two weakly
% connected components. Component connection strength = E.

g = Graphs.path(n, e);
A = g.laplacian;
full(A)

% GS spectrum
n = g.numNodes;
[v, d] = eig(eye(n) - (tril(A))\A);
[dummy1, i] = sort(abs(diag(d))); %#ok
d = d(i,i);
v = v(:,i);
lambda = diag(d);
acf = lambda(end-1);
end

%--------------------------------------------------------------------------
function y = normOfColumns(x)
% returns the vector of (separate) L2 norms of the columns of the matrix x.
y = sqrt(sum(abs(x).^2, 1));
end