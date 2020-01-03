function testListSparse()
%TESTLISTSPARSE Test the performance of accessing various
%list-of-sparse-elements implementations.
%   We investigate whether the access time to A{i} depends on size(A) or on
%   the size of A{i}, if it is itself a large matrix. It turns out that the
%   performance only depends on the total size of A (i.e. a large cell
%   array of small matrices performs the same as a small cell array of
%   large matrices. Both admit linear-scaling get and set access).

% Read input arguments if (nargin < 1)
%     nz  = 3;
% end if (nargin < 2)
%     numRuns = 10000;
% end

fprintf('Setting matrix entries\n'); 
testAddEntriesToClass(2.^(5:10), 2.^(1:4), 'MatrixBased', {'alloc', 'add', 'find'});

%fprintf('Multi-buffer matrix structure\n');
%testAddEntriesToClass(2.^(3:13), 2.^(1:3), 'MultiMatrix', {'alloc', 'add',
%'find'});
%testAddEntriesToClass(2.^(3:10), 2.^(1:2), 'MultiMatrix', {'alloc', 'add', 'find'});

%fprintf('List of hash sets of size n - time to add entries z entries to each set\n');
%testAddEntriesToClass(2.^(5:10), 2.^(1:4), 'ListSparse', {'alloc', 'add'});

% O(n z log z) ops for adding O(n z) list entries because of re-allocation
% overhead. Finding entries: O(n z).
fprintf('Struct of size n with vectors of size z - time to add entries z entries to each set\n');
testAddEntriesToClass(2.^(5:10), 2.^(1:4), 'CellExpandingArray', {'alloc', 'add', 'find'});

fprintf('Sparse matrix nxn, nnz = n*z - time to add entries z entries to each set\n');
testAddEntriesToClass(2.^(5:10), 2.^(1:4), 'SparseMatrix', {'alloc', 'add'});

end

%--------------------------------------------------------------------------
function testAddEntriesToClass(N, Z, clazz, columnTitles)
% Test allocating a ListSparse and adding elements to its HashSet elements.

numColumns = numel(columnTitles);
for z = Z
    addTime = zeros(numel(N),numColumns);
    fprintf('z = %-2d\n', z);
    for i = 1:numel(N)
        n = N(i);
        addTime(i,:) = testAddEntries(n, z, clazz, columnTitles);
        fprintf(' n = %-7d ', n);
        for j = 1:numColumns
        fprintf('   %s = %.2e (%.1e)', columnTitles{j}, addTime(i,j), addTime(i,j)/(n*z));
        if (i == 1)
            fprintf('%-5s' ,'');
        else
            fprintf(' %.2f', addTime(i,j)/addTime(i-1,j));
        end
        end
        fprintf('\n');
    end
    fprintf('\n');
end
end

%--------------------------------------------------------------------------
function t = testAddEntries(n, z, clazz, columnTitles)
% A single test on a cell array of size n and z non-zeros per list = cell
% array element.

t = zeros(1,2);
tStart = tic;
A = createObject(n, z, clazz);
t(1) = toc(tStart);

tStart = tic;
A.addEntriesToLists(z);
t(2) = toc(tStart);

if (numel(columnTitles) >= 3)
tStart = tic;
A.findEntries(z);
t(3) = toc(tStart);
end

end

%--------------------------------------------------------------------------
function A = createObject(n, z, clazz)
% A factory method.

switch (clazz)
    case 'CellExpandingArray'
        A = CellExpandingArray(n, z);
    case 'MatrixBased'
        A = MatrixBased(n, z);
    case 'ListSparse'
        A = ListSparse(n);
    case 'SparseMatrix'
        A = SparseMatrix(n);
    case 'MultiMatrix'
        A = MultiMatrix(n, 4);
    otherwise
        error('Unrecognized class ''%s''', clazz);
end

end
