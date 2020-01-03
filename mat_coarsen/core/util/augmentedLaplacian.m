function B = augmentedLaplacian(A)
%AUGMENTEDLAPLACIAN Non-singular augmented graph Laplacian.
%   B=AUGMENTEDLAPLACIAN(A) augments the graph Laplacian A with a span of
%   its null-space so that B is non-singular. If C is the number of
%   components of A, B is a rank-C modification of A, so A's C zero
%   eigenvalues are replaced by non-zeros while all others remain intact.
%
%   See also: COMPONENTS, COMPONENTSPAN.

y = componentSpan(A);
c = size(y,2);
B = [[A y]; [y' sparse(c)]];
