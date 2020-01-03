% Exhibits ACF = 0.585 in ML cycle at finest level
problem = ufget(250);
g = Graphs.fromAdjacency(problem.A);
% g = Graphs.testInstance('mat/uf/HB/sstmodel');
[r,s,b] = runCycleAcf('graph', g, 'randomSeed', 5, 'clearWhenDone', false);

% Debug 2-level cycle at level 8
twoLevelAcf(s,2,8);  % yields ACF = 0.392
% figure(1);
% clf;
%plotLevel(s, 8, 'coarsening', true, 'nodeSize', 0.04);

[d,details]=twoLevelAcf(s,2,8,[],'logLevel',2,'output','full');
% figure(2);
% clf;
% plot(details.asymptoticVector);
