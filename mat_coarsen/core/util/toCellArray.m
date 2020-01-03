function cellArray = toCellArray(matrix)
%TOCELLARRAY Convert a matrix to cell array.
%   Convert an NxD matrix to a cell array of size D whose cells contain
%   matrix columns.

dim = size(matrix, 2);
cellArray = cell(dim,1);
for d = 1:dim
    cellArray{d} = matrix(:,d);
end
end
