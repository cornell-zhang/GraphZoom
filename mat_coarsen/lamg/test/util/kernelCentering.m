function A = kernelCentering(K)
%kernelCentering Center a kernel matrix.
%   A=kernelCentering(K) returns a rank-3 modification of K that has zero
%   row sums and column sums. K must be square.
%
%   Note: this implementation creates a dense A from a sparse K. A more
%   efficient implementation would not explicitly form A, but compute A*x
%   directly from the rank-modification form of A.
%
%   See also: SPARSE.

n = size(K,1);
if (n ~= size(K,2))
    error('K must be square');
end

u = ones(n,1);
v = K*u/n;

A = K - (u*v') - (v*u') + ((u'*v)/n)*(u*u');
end
