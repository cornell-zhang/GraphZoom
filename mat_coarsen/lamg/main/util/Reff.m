function [r, X] = Reff(g, iValues, jValues)
%REFF Effective resistance.
%   R=REFF(SETUP,I,J) returns the effective capacitance between nodes I and
%   J in a connected graph G. If I and J are vectors, R(K) is the effective
%   capacitance between I(K) and J(K), K=1..NUMEL(I).
%
%   See also: LAMG.

lamg    = Solvers.newSolver('lamg', 'randomSeed', 1);
setup   = lamg.setup('graph', g);

n       = g.numNodes;
numI    = numel(iValues);
r       = zeros(numI, 1);
b       = zeros(n, 1);
X       = zeros(n, numI);
for k = 1:numI
    % Solve effective resistance problem
    i           = iValues(k);
    j           = jValues(k);
    b(i)        = 1;
    b(j)        = -1;
    x           = lamg.solve(setup, b, 'errorReductionTol', 1e-8);
    % Save results
    r(k)        = x(i) - x(j);
    X(:,k)      = x;
    b([i j])    = 0;
end
end
