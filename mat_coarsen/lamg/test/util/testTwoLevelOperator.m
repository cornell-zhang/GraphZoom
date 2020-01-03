%------------------------------------------------------------------------
% Two-level AMG spectral analysis. Requires a setup object in the current
% workspace.
%------------------------------------------------------------------------
nu = 2;    % #relax sweeps per cycle
g = 2;      % Energy correction

% Compute two-level operator M
M   = twoLevelOperator(setup, nu, g);
A   = setup.level{1}.A;
n   = size(A,1);
fprintf('Two level test of a 1-D grid of size %d\n', n);

% Compute asymptotic convergence factor Sort eigenvalues by descending abs
% value
[v, lam, d] = eigsort(M, 'descend');
fprintf('g=%.3f   ACF=%.3f\n', g, d(1));

% Compute worse-case L2 reduction during the first n cycles
% fprintf('Worst-case L2 error norm reduction\n'); Mn = speye(n); for iter
% = 1:20
%     Mn = Mn * M; rho = norm(full(Mn),2)^(1/iter); fprintf('iter=%3d
%     conv=%.3f\n', iter, rho);
% end

% M-simulated actual run starting from a random x
fprintf('Simulated actual run:\n');
x = randInRange(-1e+10, 1e+10, n, 1);
%x = sum(v(:,2:10),2);
xnewNorm = lpnorm(x);
fprintf('initial     |x|=%.3e\n', xnewNorm);
nCycles = 2;
% Small perturbation magntude to prevent a double principal eigenvector,
% leading to an convergence factor per cycle that alternates between two
% values. The perturbation is diminished with iter.
%e = 0.4i;
for iter = 1:30
    xoldNorm = xnewNorm;
    for j=1:nCycles
        x = M*x;
        xnewNorm = lpnorm(x);
        %x = M*x + (e/iter)*x; x = x-mean(x);
    end
    fprintf('iter=%3d    |x|=%.3e   conv=%.3f\n', iter, xnewNorm, (xnewNorm/xoldNorm)^(1/nCycles));
end
