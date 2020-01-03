% Koutis flow problem testing
% Reproduced on a smaller grid with two levels

%========================================================
% LAMG Run
%========================================================

g = Graphs.testInstance('koutis/flow');
%g = trimProblemFlow(g, 100); % Triggers elongated aggregates already
s = 8;%1;
nu = 3;
delta = 0.2; %0.1; %1e-2;
numCycles = 10; % delta = 0.01 works but elongated aggregates; 1e-3 doesn't
%lamg = Lamg('randomSeed', s, 'setupNumLevels', 2, 'maxDirectSolverSize', g.numNodes-1, 'tvSweeps', 4);
lamg = Lamg('randomSeed', s, 'tvSweeps', nu, 'coarseningWorkGuard', 0.7, ...
    'weakEdgeThreshold', delta);
setup = lamg.setup(g, 'clearWhenDone', 'false');
[x, details] = lamg.linearSolve(setup, zeros(g.numNodes,1), 'logLevel', 1, 'errorNorm', @errorNormResidualUnscaled, 'numCycles', numCycles, 'steadyStateTol', 1e-5, 'errorReductionTol', 1e-12); %#ok

% Asymptotic vector stats
A = g.laplacian;
r = A*x;
energy = (x'*A*x)/(x'*x);
%[v,d] = eigs(A,5,'sm');
%diag(d)

% Iterative refinement
[x2, details] = lamg.linearSolve(setup, 10^10*r, 'logLevel', 1, 'errorNorm', @errorNormResidualUnscaled, 'numCycles', numCycles, 'steadyStateTol', 1e-5, 'errorReductionTol', 1e-12);

%========================================================
% Extract run information
%========================================================

% Interpolation error
P = setup.level{2}.P;
T = setup.level{2}.T;
y = P*T*x;
e = x-y;
nConstraints = 16;
Ntotal = g.numNodes - nConstraints;
N = [Ntotal/40 40];
k            = cell(2,1);
index        = (1:Ntotal)';
[k{:}]       = ind2sub(N, index);
k            = [k{:}; zeros(nConstraints,1) (1:nConstraints)'];
[dummy1, ind] = sort(abs(e),'descend');
i = ind(1:10);
fprintf('Large interpolation errors:\n');
fprintf('(%4d,%2d) %5d %+.3e\n', [k(i,:) i e(i)]');
% Example bad nodes
u = i(1);
v = i(2);
% Neighorhood of a bad node
[in, out, cin, cout] = affinityInOut(setup, 1, u);
[nb, dummy2] = find(g.adjacency(:,in)); 
nbhd = union(in, nb);

%========================================================
% Plots
%========================================================

t = (1:g.numNodes)';
R = reshape(r(1:Ntotal),N);
X = setup.level{1}.x;
c = affinityCross(X, u, v);

figure(1);
plotLevel2(setup, 1, 'nodes', nbhd, 'coarsening', true, 'radius', 12, 'fontSize', 8);

% Residual 2-D field
figure(2);
i0 = k(i,1);
j0 = k(i,2);
rad = 10;
surf(R(max(i0-rad,1):min(i0+rad,size(R,1)),max(j0-rad,1):min(j0+rad,size(R,2)))');
view(2);
colorbar;

figure(3);
subplot(3,1,1);
plot(t, x);
title('Asymptotic vector x');
xlabel('u');
ylabel('x');
subplot(3,1,2);
plot(t, e);
title('Interpolation error');
xlabel('u');
ylabel('x - PTx');
subplot(3,1,3);
plot(t, abs(r));
title('Residual');
xlabel('u');
ylabel('|Ax|');
save_figure('png', 'flow/flow_interp_error.png');
%save_figure('png', 'flow/flow_residual.png');

figure(5);
plot(X([u v],:)');
title(sprintf('Test Vectors after %d sweeps. C = %.2f', nu, c));
xlabel('TV number k');
ylabel('x^{(k)}');
legend(sprintf('u=%d', u), sprintf('v=%d', v));
save_figure('png', 'flow/flow_tv_values.png');
