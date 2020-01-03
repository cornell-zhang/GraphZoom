function A = testSparseSetting(nz, numRuns)
%TESTSPARSESETTING Test the performance of setting elements of a sparse
%matrix.
%   Set random elements (some existing, some new) of sparse vectors and
%   monitor performance vs. vector size. Ideally, it should scale linearly,
%   which seems to be observed. Unfortunately, CoarseSetSparseRowImpl
%   contains similar operations (we think) but does not linearly scale.

% Read input arguments
if (nargin < 1)
    nz  = 3;
end
if (nargin < 2)
    numRuns = 10000;
end

fprintf('Initial nz = %d, #runs = %d\n\n', nz, numRuns);

fprintf('Single sparse vector:\n');
for n = 2.^(6:16)
    A = randomSparseVector(n, nz);
    tStart = tic;
    A = setElements(A, numRuns);
    fprintf('n = %-6d   nz = %-7d   time = %.6f\n', n, numel(find(A)), toc(tStart));
    %B = {A}; A = setElements(B, numRuns);
end

fprintf('\nCell array of sparse vectors:\n');
for n = 2.^(2:7)
    B = cell(n, 1);
    for i = 1:n
        B{i} = randomSparseVector(n, nz);
    end
    tStart = tic;
    %     for i = 1:n
    %         B{i} = setElements(B{i}, numRuns);
    %     end
    B = setElementsOfCellArray(B, numRuns);
    fprintf('n = %-6d   nz = %-7d   time = %.6f\n', n, numel(find(B{end})), toc(tStart));
    %B = {A}; A = setElements(B, numRuns);
end
end

%--------------------------------------------------------------------------
function A = randomSparseVector(n, nz)
% Construct a random sparse vector.
i       = ones(nz, 1);
j       = randi(n, nz, 1);
s       = rand(size(i));
%A       = sparse(j, i, s, n, 1, 2*nz);
A       = sparse(i, j, s, 1, n, 2*nz);
end

%--------------------------------------------------------------------------
function A = setElements(A, numRuns)
% Simulate aggregating many nodes. Profile this section.
n = size(A,1);
[j, dummy]  = find(A); %#ok
clear dummy;
%index   = j(2);
nj = numel(j);
for run = 1:numRuns
    if (rand < 0.3)
        index   = j(randi(nj));
    else
        index = randi(n);
    end
    A(index) = 1.2345;
    A(max(index+1,n)) = 0;
end
%fprintf('Initial size = %d, final size = %d\n', nj, numel(find(A)));
end

%--------------------------------------------------------------------------
function A = setElementsOfCellArray(A, numRuns)
% This is less efficient than setElements(A{i}) - simulates the time to
% access a cell array's cell in addition to the sparse matrix operations.
n = size(A,1);
c = rand(n,1);

for i = 1:n
    [j, dummy]  = find(A{i});
    clear dummy;
    %index   = j(2);
    nj = numel(j);
    for run = 1:numRuns
        if (rand < 0.3)
            index   = j(randi(nj));
        else
            index = randi(n);
        end
        A{i}(index) = c(index);
        A{i}(max(index+1,n)) = 0;
    end
    %fprintf('Initial size = %d, final size = %d\n', nj, numel(find(A)));
end
end
