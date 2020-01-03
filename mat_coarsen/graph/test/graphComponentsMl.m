%------------------------------------------------------------------------
% WORK IN PROGRESS - FINDING AN INDEPENDENT SET OF EDGES (GRAPH MATCHING)
% CAN BE CAST AS A MAX FLOW PROBLEM...
% http://en.wikipedia.org/wiki/Matching_%28graph_theory%29
%------------------------------------------------------------------------

%function [s,c] = graphComponentsMl(A) GRAPHCOMPONENTS  finds the connected
%components in an undirected graph using multilevel node matching.
%   [S,C] = GRAPHCOMPONENTSML(G) finds the connected components using a
%   multilevel algorithm.
%
%   A strongly connected component is a maximal group of nodes that are
%   mutually reachable without violating the edge directions. G is an
%   n-by-n sparse matrix that represents the undirected graph and must be
%   symmeteric; all nonzero entries indicate the presence of an edge. S is
%   the number of components and C is a vector indicating to which
%   component each node belongs. Any zeros in C represent nodes that do not
%   belong to a connected component. Y returns a cell array, where Y{i} is
%   the node index set of component i.
%
%   See also: GRAPHCONNCOMP.

% Read input arguments; initially let each node be its own component. c =
% component index
A   = spones(tril(A)); % Only one edge copy in nz list; omit edge weights
n   = size(A,1);

% Identify a graph matching
[i,j] = find(A);
[i j]
firstColumnNz = find(diff(j));
[i(firstColumnNz) j(firstColumnNz)]



c    = 1:n;
if (nnz(A) == 0)
    % Trivial matrix (every node is 0-degree)
    s = n;
    y = cell(n, 1);
    for index = 1:n
        y{index} = index;
    end
    return;
end

done = false;
maxIter = ceil(nnz(A)/2); % A little above #edges if diag(A)~=0, but easily computable

% Local diffusion relaxation sweeps - repeat until convergence to a
% stationary point
for iter = 1:maxIter
    cOld = c;
    for i = 1:n
        nbhrs = find(A(:,i));
        if (~isempty(nbhrs))
            c(i) = min(c(nbhrs));
        end
    end
    if (c == cOld)
        done = true;
        break;
    end
end

%end
