function [Q,D,L] = pchol(A,k)
%CHOLGSPARSE Partial Cholesky factorization.
%   [Q,D,L] = cholGsparse(A,k) performs a Cholesky factorization on the
%   first k rows and columns of a sparse symmetric positive-definite matrix
%   A.
%
%   Output:
%   Q: Shcur complement of A with respect to the elimination of the
%   first k vertices
%   D: k x k diagonal
%   L: lower triangular such that: A = L[D;0|0;Q]L^T
%
%   See also: CHOL.
%
%   Author: Yiannis Koutis <i.koutis@gmail.com>
%   Modified for faster MATLAB indexing by Oren Livne <oren.livne@utah.edu>

n   = length(A);
d   = zeros(k);         % Holds D's diagonal entries

Lnz = zeros(k+n,3);     % Holds L's non-zero list
Lnz(1:n,:) = [(1:n)' (1:n)' ones(n,1)]; % Populate L's diagonal
nnz = n;                % Keeps track of #L non-zeros

for i = 1:k             % Cholesky elimination steps on the first k rows
    % Calculate L's ith column
    range               = i+1:n;
    vi                  = A(range,i);
    di                  = A(i,i);
    d(i)                = di;
    ni                  = numel(vi);
    sz                  = size(Lnz,1);
    if (nnz + ni > sz)
        % Exceeded current allocation, reallocate Lnz at twice the size
        temp            = Lnz;
        Lnz             = zeros(2*sz, 3);
        Lnz(1:nnz,:)    = temp(1:nnz,:);
    end
    Lnz(nnz+1:nnz+ni,:) = [range' repmat(i, ni, 1) vi/di];
    nnz                 = nnz + ni;

    % Update A upon eliminating row i & col i
    Z           = vi*vi'/di;
    [iz,jz,V]   = find(Z);
    Z           = sparse(iz+i,jz+i,V,n,n);
    A           = A - Z;
end

% Prepare output arguments
Lnz = Lnz(1:nnz,:);
L   = sparse(Lnz(:,1), Lnz(:,2), Lnz(:,3), n, n);
D   = spdiags(d,0,k,k);
Q   = A(range,range);       % range was already populated in the main loop
