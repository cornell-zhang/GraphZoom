function bins = undecidedNodes_matlab(A, candidate, isOpen, numBins)
%UNDECIDEDNODES Find undecided nodes (MATLAB implementation).
%   BINS=undecidedNodes(A, CANDIDATE, ISOPEN, NUMBINS) returns a cell array
%   of size NUMBINS indicating which undecides nodes have open neighbors on
%   the undirected graph whose totally-positive symmetric adjacency matrix
%   is A. Open nodes are non-associate nodes (seeds or undecided), i.e.,
%   nodes with which other nodes can be associated. CANDIDATE is the list
%   of of undecided nodes to consider, and ISOPEN is a logical array
%   indicating whether a node is open. Undecided nodes are binned into BIN
%   cells by descending strongest connection to an open node.
%
%   With two output arguments, AMAX is set to MAX(A(undecided,isOpen), [],
%   2), i.e., a vector of the maximum connections between each undecided
%   node and open nodes.
%
%   See also: COARSESET, COARSESETAFFINITYMEX.

candidate = candidate(sum(spones(A(isOpen,candidate))) > 0);
Amax = max(A(isOpen,candidate), [], 1);
bins = cellfun(@(x)(candidate(x)), binsort(Amax, numBins), ...
    'UniformOutput', false);
end
