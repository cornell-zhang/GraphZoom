function [f, c, status] = lowDegreeNodes(A, d, maxDegree)
%LOWDEGREENODES Identify low degree graph nodes to be eliminated in a
%singly connected graph.
%   [F,C,STATUS]=LOWDEGREENODES(A,D,MAXDEGREE) returns the indices of an
%   independent set of (<=MAXDEGREE)-degree nodes (F), and the rest of the
%   nodes (C), in a symmetric adjacency matrix A. All F nodes are
%   independent of each other, i.e., A(F,F) is diagonal. D is a vector of
%   node degrees; if empty, it is internally set to SUM(SPONES(A)).
%
%   Note: A can also be a graph Laplacian (in which case A's diagonal is
%   ignored), or only the sparsity pattern of the adjacency matrix (weights
%   are not used).
%
%   [F,C,STATUS]=LOWDEGREENODES(A) is equivalent to [F,C,STATUS]=LOWDEGREENODES(A,3).
%
%   See also: CoarseningStrategyLowImpact, amd.

% Status flag array coding schema. Must match elimination.h
LOW_DEGREE  = 1;
HIGH_DEGREE = 2;

% Initializations
if (nargin < 2)
    maxDegree = 3;
end
if ((nargin < 2) || isempty(d))
    %d = sum(spones(A));
    d = sum(A ~= 0, 1); % Could be improved a little by MEX
end
candidate          = find(d <= maxDegree);
status             = HIGH_DEGREE * ones(size(A,1), 1);
status(candidate)  = 0;         % Reset all relevant nodes to "not visited"

% Call MEX function for the computationally-intensive step of marking nodes
status = lowdegreesweep(status, A, candidate);

% Format flag array as output
if (nargout >= 1)
    f = find(status == LOW_DEGREE);
end
if (nargout >= 2)
    %c  = find((status == NOT_ELIMINATED) | (status == HIGH_DEGREE));
    c  = find(status ~= LOW_DEGREE);
end

% Never allow the elimination of all nodes. Leave at least one node in c.
if (isempty(c))
    c = f(1);
    f = f(2:end);
end

end
