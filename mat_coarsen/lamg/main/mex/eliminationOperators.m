%ELIMINATIONOPERATORS Elimination operators.
%   [R,Q]=eliminationOperators(A,F,C_INDEX) returns the C-to-F restriction
%   operator R=(A(F,F)\A(F,C))^T and the affine term operator
%   Q=1./diag(A(F,F)) for an F-C node partitioning of an undirected graph
%   with the adjacency matrix A. C_INDEX is an array whose Ith element is 0
%   if I is not in C and the index in the C set of I, if I is in C.
%
%   see also: LOWDEGREENODES, COARSESTRATEGYELIMINATION.
