function [g0, x] = testDefectCorrection(g1, eta)
%TESTDEFECTCORRECTION Defect correction test for a graph with many small
%entries.
%   G0=TESTDEFECTCORRECTION(G1, ETA) tests a defect correction scheme: G1.LAPLACIAN
%   is approximated by a sparser graph G0 for which an AMG cycle is
%   constructed. The G1 problem is solved using this cycle with a defect
%   correction (G1-G0). ETA is the sparsification threshold.
%
%   See also: filterSmallEntriesSym

% Construct a "lower-order" operator A0 consisting of strong connections
% only
W0  = filterSmallEntriesSym(g1.adjacency, eta);
g0  = Graphs.fromAdjacency(W0);

fprintf('Solving g0 problem:\n');
lamg    = Lamg();
setup   = lamg.setup(g0, 'clearWhenDone', 'false');
disp(setup);
solveG0(lamg, setup);

fprintf('Solving g1 problem with g0 defect correction:\n');
x = solveG1(lamg, setup, g1);
end

%----------------------------------------------------------------
function solveG0(lamg, setup)
% Solve A0*x=0 using cycles.
g0      = setup.level{1}.g;
n       = g0.numNodes;
b       = zeros(n,1);
cycle   = Cycles.solveCycle(setup, b, lamg.mlOptions);
problem = lamg.toProblem(g0, b);
x       = rand(n,1);
i       = 0;
eNew    = lamg.mlOptions.errorNorm(problem, x);
fprintf('ITER    |b-Ax|     ACF \n');
fprintf('%2d  %.3e\n', i, eNew);
for i = 1:10
    x = cycle.run(x);
    eOld = eNew;
    eNew = lamg.mlOptions.errorNorm(problem, x);
    fprintf('%2d  %.3e  (%.3f)\n', i, eNew, eNew/(eOld+eps));
end
end

%----------------------------------------------------------------
function x = solveG1(lamg, setup, g1)
% Solve A1*x=0 using cycles set up for A0.
g0      = setup.level{1}.g;
TAU     = g1.laplacian-g0.laplacian;
n       = g0.numNodes;
x       = rand(n,1);
b1      = zeros(n,1);
i       = 0;
problem = lamg.toProblem(g1, b1);
eNew    = lamg.mlOptions.errorNorm(problem, x);
fprintf('ITER    |b-Ax|     ACF     |TAU|\n');
fprintf('%2d  %.3e\n', i, eNew);
for i = 1:10
    tau     = TAU*x;
    b       = b1 + tau;
    cycle   = Cycles.solveCycle(setup, b, lamg.mlOptions);
    x       = cycle.run(x);
    eOld    = eNew;
    eNew    = lamg.mlOptions.errorNorm(problem, x);
    fprintf('%2d  %.3e  (%.3f)  %.3e\n', i, eNew, eNew/(eOld+eps), norm(tau));
end
end
