function umfpackTiming()
%umfpackTiming Compare UMFPack linear solution time.
%   This test function compares the backslash operator speed for two graph
%   Laplacian matrices of comparable number of edges. Both seem to arise
%   from a geometric discretization. However, the solution times per edge
%   are very different.
%
%   See also: MLDIVIDE.

% Laplacian #1: based on the sparsity pattern of the following symmetric
% non-zero-row-sum UF problem
clear all;
problem = ufget('Pothen/bodyy5');
A = problem.A;
W = diag(diag(A))-A;
W = spones(W);
A = diag(sum(W))-W;
linearSolve(A);

% Laplacian #2
clear all;
problem = ufget('AG-Monien/ccc');
W = problem.A;
A = diag(sum(W))-W;
linearSolve(A);
end

%------------------------------------------------------------------------
function t = linearSolve(A)
% Solve A*x=b with a compatible RHS b. Return the run time t.
numNodes = size(A,1);
numEdges = (numel(nonzeros(A))-numNodes)/2;

% Augment the system to make it nonsingular
b = [1; -1; zeros(numNodes-1, 1)];
u = ones(numNodes, 1);
A = [[A u]; [u' 0]];

% Solve with UMFPack
tStart = tic;
x = A\b; %#ok
t = toc(tStart);
fprintf('n = %6d, m = %7d, time = %.2e [sec], time/m = %.2e [sec]\n', ...
    numNodes, numEdges, t, t/numEdges);
end
