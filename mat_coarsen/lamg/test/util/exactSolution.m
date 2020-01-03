function x = exactSolution(problem, setup) %#ok
%EXACTSOLUTION exact solution to an eigenvalue Problem object.
%   Used to test for cycle stationarity: exact solution initial
%   guess.
%
%   See also: EIGENPAIR, EIG.

% TODO: extend to K eigenpairs

%fineLevel  = setup.level{1};
% Assuming a singly-connected graph
[X, LAM]   = smallestEig(problem.A, problem.B, problem.K+1);
x          = amg.eig.Eigenpair(X(:,end), LAM(end));
