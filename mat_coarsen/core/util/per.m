function x = per(x, n)
%PER Periodic indexing.
%   Y = PER(X,N) returns the 1-based index of a subscript vector
%   X=(X(1)..X(D)) in a periodic grid of size N=(N(1)..N(D)). That is, 1 <=
%   Y(i) <= N(i) for all i = 1..LENGTH(X). If X is an MxD matrix, then Y is
%   an MxD matrix whose rows are the periodic indices of the rows of X
%
%   Not based on the slow MOD any more; works correctly only for the first few
%   gridpoints on theleft and right of each boundary and for a vector X and
%   scalar N.

%N = repmat(n, size(x)./size(n));
%y = mod(x+N-1,N)+1;

ind = find(x < 1);
x(ind) = x(ind) + n;
ind = find(x > n);
x(ind) = x(ind) - n;

end
