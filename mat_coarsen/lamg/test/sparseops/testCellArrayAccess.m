function testCellArrayAccess()
%TESTCELLARRAYACCESS Test the performance of accessing cell arrays.
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

fprintf('Cell array access time test; fixed m; n -> infinity\n');
for m = 2.^(3:6)
for n = 2.^(8:14)
    testCellArray(n, m);
end
fprintf('\n');
end

fprintf('Cell array access time test; m -> infinity; fixed n\n');
n = 10;
for m = 2.^(8:14)
    testCellArray(n, m);
end

end

%--------------------------------------------------------------------------
function testCellArray(n, m)
% A single test on a cell array of size n, whose cells are matrices of size
% m x (some constant).

tStart = tic;
A = CellClass(n, m);
allocationTime = toc(tStart);

tStart = tic;
A.setCells();
accessTime = toc(tStart);

tStart = tic;
A.setEntries();
setTime = toc(tStart);

fprintf('n = %-6d m = %-7d allocation = %.6f   cell = %.6f   entries = %.6f\n', ...
    n, m, allocationTime, accessTime, setTime);
end
