function [r, data] = plotResultTrends(r)
% Correlate slow graphs with graph statistics

%load('C:\oren\out\beagle\beagle_results_20120202.mat');

numLevels = cellfun(@(x)(x{1}.numLevels), r.details);
i = find(r.dataColumns('lamgSuccess') ...
    & (r.dataColumns('numEdges') > 1e5) ...
    & (numLevels >= 3));
r = r.subset(i); %#ok

weak = cellfun(@(x)(x{1}.weakEdgePortion), r.details);
numLevels = cellfun(@(x)(x{1}.numLevels), r.details);
setupEdges = cellfun(@(x)(x{1}.setup.edgeComplexity * x{1}.setup.edges(1)), r.details);
degLevel2 = cellfun(@(x)(2*x{1}.setup.edges(2)/x{1}.setup.nodes(2)), r.details);

tSetup = r.dataColumns('lamgTSetup');
tSolve = r.dataColumns('lamgTSolve');
n = r.dataColumns('numNodes');
m = r.dataColumns('numEdges');
nm = n + m;
degL1 = (2*m)./n;

data = [n m nm weak numLevels setupEdges degL1 degLevel2 tSetup tSolve];

C = corrcoef(data);
format
C(1:end-2,end-1:end)

fig=101;

figure(fig);
fig=fig+1;
clf;
semilogx(m, tSetup, 'bo', m, tSolve, 'ro');
xlabel('# Edges');
ylabel('Time / edge');
legend('tSetup', 'tSolve', 'Location', 'Northwest');

figure(fig);
fig=fig+1;
clf;
semilogx(nm, tSetup, 'bo', nm, tSolve, 'ro');
xlabel('# Edges + # Nodes');
ylabel('Time / edge');
legend('tSetup', 'tSolve', 'Location', 'Northwest');

figure(fig);
fig=fig+1;
clf;
plot(weak, tSetup, 'bo', weak, tSolve, 'ro');
xlabel('Weak Edge Portion');
ylabel('Time / edge');
legend('tSetup', 'tSolve');

figure(fig);
fig=fig+1;
clf;
plot(numLevels, tSetup, 'o');
xlabel('# Levels');
ylabel('Setup Time / edge');

figure(fig);
fig=fig+1;
clf;
semilogx(setupEdges, tSetup, 'o');
xlabel('Total Setup Edges');
ylabel('Setup Time / edge');

figure(fig);
fig=fig+1;
clf;
plot(degL1, tSetup, 'o');
xlabel('Average Degree');
ylabel('Setup Time / edge');
end
