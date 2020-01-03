%TESTPATHRANDOM Test LAMG complexity for path+random graphs vs. graph size.

gg = @(n)(Graphs.pathPlusSmallRandom(n, 1e-6, 3/n));
n = 4000*2.^(0:7);
solver = 'lamg'; %'cmg';

sz      = numel(n);
m       = zeros(sz,1);
tSetup  = zeros(sz,1);
tSolve  = zeros(sz,1);
work    = zeros(sz,1);
for i = 1:sz
    g = gg(n(i));
    [r,s,b] = Solvers.runSolvers('graph', g, 'solvers', {solver}, 'clearWhenDOne', false); s=s.setup;
    m(i)        = g.numEdges;
    tSetup(i)   = r.details{1}.tSetup;
    tSolve(i)   = r.details{1}.tSolve;
    if (strcmp(solver, 'lamg'))
        work(i)     = s.cycleComplexity;
    end
end

figure(1);
clf;
semilogx(m, tSetup, 'bo-', m, tSolve, 'ro-');
legend('Setup Time', 'Solve Time');
xlabel('#Edges');

figure(2);
clf;
semilogx(m, work, 'bo-');
xlabel('#Edges');
ylabel('Estimated Cycle Work');