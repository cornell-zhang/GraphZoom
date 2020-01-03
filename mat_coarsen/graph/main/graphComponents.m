function [s,c,y] = graphComponents(A)
%GRAPHCOMPONENTS  finds the connected components in an undirected graph
%using relaxation.
%   [S,C,Y] = GRAPHCOMPONENTS(G) finds the strongly connected components
%   using a relaxation algorithm. It is recommended only for SMALL GRAPHS.
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
n    = size(A,1);
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

if (~done)
    error('Relaxation did not converge in %d iterations', maxIter);
else
    % Recode connected component indices to running indices
    runningIndex = zeros(1,n);
    s = 0;
    for i = 1:n
        if (runningIndex(c(i)) == 0)
            s = s+1;
            runningIndex(c(i)) = s;
        end
    end
    c = runningIndex(c);
    
    % Prepare component index set cell array
    if (nargout >= 3)
        y = cell(s, 1);
        for index = 1:s
            y{index} = find(c == index)';
        end
    end
end

end
