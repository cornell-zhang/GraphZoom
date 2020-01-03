g = Graphs.testInstance('uf/AG-Monien/airfoil1_dual');
[r,s,b] = runCycleAcf('graph', g, 'randomSeed', 5, 'clearWhenDone', false, ...
    'maxDirectSolverSize', 40);
s

for l = 1:2:s.numLevels
    plotLevel2(s, l, 'radius', .5, 'fontsize', 0);
    axis off;
    eval(sprintf('print -deps airfoil_%d.eps', l));
end
