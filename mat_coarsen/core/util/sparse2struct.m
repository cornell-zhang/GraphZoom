function s = sparse2struct(A)
%SPARSE2STRUCT Convert a square sparse matrix into a struct array.
%   This change in data structure may be more efficient for accessing A
%   columns in a sequential loop. S=SPARSE2STRUCT(A) assumes A is an NxN
%   square matrix. S is a struct array of size N; S(I) represents A's I-th
%   column.
%
%   See also: STRUCT, SPARSE.

% Allocate affinity struct
[i,dummy,a]     = find(A);
clear dummy;
n           = size(A,2);
s           = repmat(struct('index', zeros(0, 1), 'value', zeros(0, 1)), [n 1]);
rowSize     = sum(A > 0,1)';
colEnd      = cumsum(rowSize);
colBegin    = [1; colEnd(1:end-1)+1];

% Populate struct entries, each corresponding to an A-column
for j = 1:n
    j1 = colBegin(j);
    j2 = colEnd(j);
    if (j2 > j1)
        s(j).index  = i(j1:j2);
        s(j).value  = a(j1:j2);
    end
end

end

