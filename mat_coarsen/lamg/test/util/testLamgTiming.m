% LAMG setup, solve costs test, intended for use with the MATLAB profiler.

% Load problem
clear g;
%g = Problems.laplacianGraphFromTestInstance('lap/uf/Wissgott/parabolic_fem');
g = Graphs.testInstance('lap/uf/DIMACS10/hugetric-00010');
A = g.laplacian;
setRandomSeed(1);
b = rand(g.numNodes, 1);
b = b - mean(b);

% Initialize solver
lamg = Solvers.newSolver('lamg', 'randomSeed', 1, 'tvNum', 1);

profile viewer

% Setup command
% tic; setup = lamg.setup(g); toc;

% Solve command
% tic; lamg.solve(setup, [], b, 'errorReductionTol', 1e-8); toc;
