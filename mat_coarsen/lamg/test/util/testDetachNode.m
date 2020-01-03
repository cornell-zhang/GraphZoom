function acf = testDetachNode(s, l, i, varargin)
%testRandomSeed test with different random seeds.
% Test a small graph that exhibits a coarsening problem only for certain
% random RV starts.

%g = Graphs.testInstance('uf/Pajek/GD97_b');
%g = Graphs.testInstance('ml/GD97_b/level-2');
%g = Graphs.testInstance('ml/ilya/web-stanford/l11/level-21');
%g = Graphs.testInstance(key);

%g = Graphs.testInstance(key);
%r = testCycleAcf('graph', g, 'randomSeed', 31, 'ratioMax', 3, 'setupNumLevels', 2, 'clearWhenDone', false, 'output', 'full', 'nu', 2, 'numCycles', 20);

% Remove nodes
lc = l+1;
lev = s.level{lc};
P = lev.P;
lev.detachNode(i);
fprintf('New #aggregates = %d\n', lev.size);
%disp(s.setup);

% Compute 2-level ACF without the nodes
%data = twoLevelAcf(s, 2, l, 0);
data = twoLevelAcf(s, 2, l, Inf);
acf = data(2);

% Restore original level
lev.setP(P);

% N   = (1:g.numNodes)';
% acf = zeros(size(N));
% for k = 1:numel(N)
%     i = N(k);
%     acf(k) = result.details{1}.index;
%     [i acf(k)]
% end
% acf = [N acf];
