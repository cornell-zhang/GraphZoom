function A = testSparseAggregation(n, nz)
%TESTSPARSEAGGREGATION Test the performance of merging nodes in a sparse
%matrix.
%   Detailed explanation goes here

% Read input arguments
if (nargin < 1)
    n   = 100;
end
if (nargin < 2)
    nz  = 3;
end

A = randomLaplacian(n, nz);
simulateAggregation(A);
end

%--------------------------------------------------------------------------
function L = randomLaplacian(n, nz)
% Construct a random adjacency matrix and return its graph Laplacian.
nnz     = n*nz;
i       = repmat(1:n, nz, 1);
i       = i(:);
j       = randi(n, nnz, 1);
s       = rand(size(i));

A       = sparse(i, j, s, n, n, 2*nnz);
A       = A - diag(diag(A));
g       = graph.api.Graph.newNamedInstance('random', graph.api.GraphType.UNDIRECTED, A);
L       = g.laplacian;
end

%--------------------------------------------------------------------------
function simulateAggregation(A)
% Simulate aggregating many nodes. Profile this section.
n = size(A, 1);
for step = 1:floor(n/2)
    % Simulate aggregating i and i+1 in-place into i
    i   = 1; %2*step-1;
    j   = i+1;
    
    ai  = find(A(:,i));
    aj  = find(A(:,j));
    
    % Frees space that is already allocated
    A(:,j)      = [];
    %A(j,:)      = 0;
    
    % Use that space in a different row
    A(:,i)     = max(A(:,i), A(:,j));
    %A(aj,i)     = A(aj,j);
    
    % Symmetrize
    %A(i,ai)    = A(ai,i);
    %A(i,aj)    = A(aj,i);
    
    %     % Use that space in a different row
    %     iValues     = rand(size(ai));
    %     jValues     = rand(size(aj));
    %     A(ai,i)     = iValues;
    %     A(aj,i)     = jValues;
    %
    %     % Symmetrize
    %     A(i,ai)     = iValues;
    %     A(i,aj)     = jValues;
end
end
