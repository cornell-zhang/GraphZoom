function s = independentUndecided(A, candidate, stat)
%INDEPENDENTUNDECIDED Independent set of undecided nodes.
%   S=INDEPENDENTUNDECIDED(A,CANDIDATE,STAT) returns a logical array
%   indicating whether each CANDIDATE node is an A-independent set of
%   negative-STAT nodes. A is a symmetric graph adjacency matrix.
%   CANDIDATE nodes are all assumed to have negative status.
%
%   See also: LOWDEGREENODES.

% Status flag array coding schema. Must match elimination.h
LOW_DEGREE  = 1;
HIGH_DEGREE = 2;

% Initializations
status              = HIGH_DEGREE * ones(size(A,1), 1);
status(stat < 0)    = LOW_DEGREE;   % Mark all negative-status nodes as "candidates for independent set"
status(candidate)   = 0;        	% ... but then reset all relevant nodes to "not visited"

% Call MEX function for the computationally-intensive step of marking nodes
status = lowdegreesweep(status, A, candidate);

% Format flag array as output
s = find(status == LOW_DEGREE);

end
