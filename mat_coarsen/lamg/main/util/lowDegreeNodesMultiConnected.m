function [z,f,c] = lowDegreeNodesMultiConnected(A, d, maxDegree)
%LOWDEGREENODES Identify low degree graph nodes to be eliminated in multi-connected graphs.
%   [Z,F,C]=LOWDEGREENODES(A,D,MAXDEGREE) returns the indices of 0-degree
%   nodes (Z), (<=MAXDEGREE)-degree nodes (F) and the rest of the nodes
%   (C) in a symmetric adjacency matrix A. All F nodes are independent of
%   each other (i.e. A(F,F) is diagonal). D is a vector of node degrees; if empty,
%   it is internally set to SUM(SPONES(A)).
%
%   [Z,F,C]=LOWDEGREENODES(A) is equivalent to
%   [Z,F,C]=LOWDEGREENODES(A,3).
%
%   See also: CoarseningStrategyLowImpact, amd.

if (nargin < 2)
    maxDegree = 3;
end

% Initializations
if ((nargin < 2) || isempty(d))
    d = sum(spones(A));
end
z           = find(~d)';  % 0-degree nodes
candidate   = find((d > 0) & (d <= maxDegree));

% visited flag array coding schema
ZERO_DEGREE     = 1;
HIGH_DEGREE     = 2;
LOW_DEGREE      = 3;
NOT_ELIMINATED  = 4;

% Initial node marking
n                   = size(A,1);
visited             = HIGH_DEGREE * ones(n,1);
visited(z)          = ZERO_DEGREE;
visited(candidate)  = 0;         % Reset all relevant nodes to "not visited"

% Call MEX function to perform the compututationally intensive part of
% marking nodes
visited = lowdegreesweep(visited, A, candidate, uint32(maxDegree));

% Format flag array as output
if (nargout >= 2)
    f = find(visited == LOW_DEGREE);
end
if (nargout >= 3)
    c  = find((visited == NOT_ELIMINATED) | (visited == HIGH_DEGREE));
end

end
