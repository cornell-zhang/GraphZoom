function [x, lam, alpha, indeterminate, r] = rayleighRitz(A, B, x, K)
%RAYLEIGHRITZ Rayleigh-Ritz projection.
%   [Y,LAMBDA,ALPHA,INDETERMINATE]=RAYLEIGHRITZ(A,B,X,K) returns recombinations Y=X*ALPHA
%   of the columns of X that form the best orthonormal basis (in the energy
%   norm) for the subspace spanned by the K lowest eigenvectors of the
%   pencil (A,B). LAMBDA is the vector of corresponding eigenvalues.
%   INDETERMINATE is the number of indeterminate eigenvalues of the pencil
%   (A,B) (when both A and B have a common zero mode).
%
%   K must be less than or equal to SIZE(X,2). A and B must be symmetric or
%   complex Hermitian.
%
%   See also: RAYLEIGHQUOTIENT, EIG.

% Validate input arguments
if (K > size(x,2))
    error('MATLAB:rayleighRitz:InputArg', 'Too few columns available for the request number of eigenpairs');
end

% Set up the Ritz pencil
xt      = x';
if (isa(A, 'function_handle'))
    r.A     = A(x);
else
    r.A     = A*x;
end
r.B     = B*x;
ritzA   = full(xt*r.A);
ritzB   = full(xt*r.B);

% Solve Ritz problem
if (issparse(ritzA) || issparse(ritzB))
    [v, d] = eigs(ritzA, ritzB);
else
    [v, d] = eig(ritzA, ritzB);
end
d = diag(d);

% Filter vectors with B*v=0 corresponding to indefinite lam values
spurious        = abs(sum(v.*(ritzB*v), 1)) < 1e-15;
indeterminate   = numel(find(spurious));
d(spurious)     = [];
v(:,spurious)   = [];
if (length(d) < K)
    error('MATLAB:rayleighRitz:Degenerate', 'Insufficient number of non-spurious eigenpairs were found');
end

% Find the K lowest eigenpairs
[dummy, index]      = sort(d, 'ascend'); %#ok
clear dummy;
%lam             = d(1:K); % Could be less numerically stable than
%recomputing RQ's from the recombined x's below
alpha           = v(:,index(1:K));
x               = x*alpha;
r.A             = r.A*alpha;
r.B             = r.B*alpha;

% Normalize eigenvectors since eig normalizes eigenvectors to L_infinity=1
xNorm           = sqrt(sum(x.*r.B, 1));
c               = 1./ xNorm(ones(size(x,1),1),:);
x               = c.*x;
r.A             = c.*r.A;
r.B             = c.*r.B;
lam             = sum(x.*r.A, 1);
