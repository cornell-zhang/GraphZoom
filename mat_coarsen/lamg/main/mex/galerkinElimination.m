%GALERKINCALIBER1 Elimination Galerkin operator.
%   B=galerkinElimination(A,R,STATUS,C,INDEX) returns B = A(C,C) +
%   P*A(C,F), where P is the elimination interpolation corresponding to an
%   F-C node splitting of the NxN graph Laplacian A. STATUS is a status
%   array of size N indicating whether each node is an F- or C-vector (see
%   elimination.h or lowDegreeNodes.m for value convention). C is the set
%   of C-points. INDEX is an array of size N s.t. INDEX(I) is a running
%   index over F nodes if I is in F, and a running index over C-nodes if I
%   is in C.
%
%   See also: LOWDEGREENODES, GALERKINCALIBER1, COARSESETELIMINATION.