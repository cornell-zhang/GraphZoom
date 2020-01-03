function [s,acf,details] = twoLevelEnergyRatio(key, randomSeed, doRun, varargin)
%------------------------------------------------------------------------
% To re-generate problematic intermediate level from original problem:
%   g = Graphs.testInstance('uf/SNAP/amazon0312');
%   [r,s,b] = runCycleAcf('graph', g, 'randomSeed', 5, 'clearWhenDone', false, 'gamma', 1.2, 'guard', 0.7);
%   graphWrite(s.level{7}.g, 'ml/uf/SNAP/amazon0312', 'level-7-b');
%	stats: 42313 nodes / 185846 edges
%
%   For level-7-b, randomSeed = 3:
%   1     FINEST   42313   185846   0     1.000    4.39   1   1.2  1.00  8
%   2     AGG     19853   121188   0     0.469    6.10   1   1.2  0.92  9
%
%   Two-level results (gamTwoLev>=2.0):
%   * s based on min(size(aggSize))): ACF = 0.685  bad nodes: 26693  14676
%   * s based on max(affinity):       ACF = 0.412  bad nodes: 33084 (sun that becomes an associate), 35306

if (nargin < 3)
    doRun       = 1;
end
%randomSeed  = 1; %2;        %5;
%key         = 'uf/HB/bcsstk19'; %'uf/FIDAP/ex35'; %'uf/HB/lshp1561'; %'uf/AG-Monien/airfoil1'; %'ml/uf/SNAP/amazon0312-c/level-8'; %'ml/uf/SNAP/amazon0312/level-7';
k           = 1;
gamTwoLev   = 2.0;
numCycles   = 12;

g = Graphs.testInstance(key);
if (doRun)
    [dummy1, s, dummy2] = Solvers.runSolvers('graph', g, 'solvers', {'lamg'}, 'randomSeed', randomSeed, 'clearWhenDone', false,...
        varargin{:}); %#ok
    s = s.setup;
    [acf,details] = twoLevelAcf(s,100,k,gamTwoLev,s.level{k+1}.g.numNodes+1,'output','full','numCycles',numCycles,varargin{:});
else
    s = varargin{1};
    acf = varargin{2};
    details = varargin{3};
end

l = s.level{k};
lc = s.level{k+1};
x = details.asymptoticVector;
r = l.A*x;
e = lc.restrict(l.nodalEnergy(x)); %#ok
ec = lc.nodalEnergy(lc.coarseType(x)); %#ok
q = lc.nodalEnergy(lc.coarseType(x)) ./ (lc.restrict(l.nodalEnergy(x))+eps); %#ok
figNum = 0;

% Plot asymptotic error, residual
figNum = figNum+1;
figure(figNum);
clf;
subplot(2,1,1);
plot(x);
xlim([0 l.g.numNodes+1]);
title('Asymptotic Two-level vector x');

subplot(2,1,2);
plot(abs(r));
xlim([0 l.g.numNodes+1]);
title('r = Ax (pointwise abs value)');

% Find slowest-to-converge fine nodes u and corresponding coarse nodes U
badScenarios = 5;
[R, i]=sort(abs(r),'descend');
u = i(1:badScenarios);
[U, dummy] = find(lc.T(:,u)); %#ok
fprintf('Median |r| = %.2e\n', median(R));
fprintf('Largest residuals at fine nodes (u), aggregate index (U):\n');
fprintf('%6d %6d %.2e\n', [u'; U'; R(1:badScenarios)']);

% Bad aggregate stats + neighborhood plot
for i = 1:badScenarios
    [in, out, cin, cout] = affinityInOut(s,k,u(i)); %#ok
    if (numel(in)==1)
        nodes = [in; out];
    else
        nodes = [in out];
    end
    figNum = figNum+1;
    figure(figNum);
    clf;
    plotLevel(s, 1, 'radius', 15, 'nodes', nodes, 'fontSize', 8, ...
        'coarsening', true, 'affinity', true);shg
    title(sprintf('Bad node #%d: u=%d', i, u(i)));
end

% Affinity distribution
C = affinitymatrix(l.g.adjacency, l.x);
c = nonzeros(C);
if (1)
    figNum = figNum+1;
    figure(figNum);
    clf;
    hist(-log10(max(eps, 1-c)),100);
    xlabel('-log_{10}(1-c)');
    xlim([0 8]);
end

end
