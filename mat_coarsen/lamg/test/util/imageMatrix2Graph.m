function g = imageMatrix2Graph(W)
%IMAGEMATRIX2GRAPH Convert image similarity matrix to a graph.
%   G=imageMatrix2Graph(W) converts an adjacency matrix W to a graph. W's
%   diagonal is ignore. W is assumed to correspond to an NxN pixel image
%   where N=SQRT(SIZE(W,1)).
%
%   See also: GRAPH, GRAPHS, IND2SUB.

% Compute node coordinates
n = sqrt(size(W,1)); 
[i,j] = ind2sub([n n], (1:n^2)'); 
coord = [i j];

g = Graphs.fromAdjacency(W, coord);

end
