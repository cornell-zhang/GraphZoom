%GSRELAX gauss-seidel relaxation.
%   Y=GSRELAX(A,B,X,NU) performs NU Gauss-Seidel relaxation sweeps on
%   A*X=B. A is a symmetric real-valued N-by-N sparse left-hand-side
%   matrix, B is a real N-by-P right-hand-side matrix, and X is a N-by-P
%   real initial guess. Y is N-by-P.
%
%   WARNING: if you pass a non-symmetric matrix into this method, no error
%   will be reported, but the result will be wrong.
%
%   see also: RELAX.
