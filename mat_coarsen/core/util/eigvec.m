function [S, D] = eigvec(A)
%EIGVEC  Eigenvectors and their geometric multiplicity.
%
% S = eigvec(A) returns the largest possible set of linearly independent
% eigenvectors of A.
%
% [S, D] = eigvec(A) also returns the corresponding eigenvalues in the
% diagonal matrix D. Each eigenvalue in D is repeated according to the
% number of its linearly independent eigenvectors. This is its geometric
% multiplicity.
%
% Always A*S = S*D. If S is square then A is diagonalizable and inv(S)*A*S
% = D = LAMBDA.
%
% Taken from http://web.mit.edu/18.06/www/Course-Info/Mfiles/eigvec.m.

n = size(A,2);
I = eye(n);
evalues = eigval(A);
S = [];
d = [];
t = 0;
for k = 1:length(evalues);
    s = nulbasis(A - evalues(k)*I);
    ns = size(s,2);
    S = [S s];
    [evalues(k) ns]
    t = t+ns;
    temp = ones(ns, 1) * evalues(k);
    d = [d; temp];
end
D = diag(d);
t
