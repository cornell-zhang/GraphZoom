%MEDIANCOL Near-median by sparse matrix column indices.
%   Y=medianCol(A,X) computes the near-median of values in an N-vector X
%   over the indices of non-zeros in each column of the NxN matrix A, and
%   returns the result in the N-vector Y. More precisely, for each J=1..N,
%   Y(J) is the [K/2+1]th largest element in the list
%   (X(I(1)),...,X(I(K))), where A(:,J) has non-zero elements at indices
%   I(1),...,I(K).
%
%   See also: SPARSE, MEDIAN.
