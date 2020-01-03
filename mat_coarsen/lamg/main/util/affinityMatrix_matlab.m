function C = affinityMatrix_matlab(W, x)
%AFFINITYMATRIX Affinity matrix between all graph nodes.
%   C=AFFINITYMATRIX_MATLAB(W,X) returns a matrix C whose sparsity pattern
%   equals W's and whose entry C(I,J) is the affinity between X(I,:) and
%   X(J,:).
%
%   See also: AFFINITY_L2.

[i,j]   = find(W);

% Note: the following line requires a lot of memory. Break down i, j into
% manageable blocks instead.

nz          = numel(i);
c           = zeros(nz,1);
% Note: block size depends on amount of memory on the machine. TODO: make
% it an adjustable parameter
BLOCK_SIZE  = 1e6;
first       = 1;
while (first <= nz)
    last = min(nz, first+BLOCK_SIZE-1);
    range = first:last;
    I = i(range);
    J = j(range);
    c(range) = affinity_l2(x(I,:), x(J,:));
    first = first + BLOCK_SIZE;
end

C = sparse(i, j, c, size(W,1), size(W,2));

end
