function results = testGrid(gridType, d, N, print, varargin)
%TESTGRID LMG ACF test for a grid graph.
%   RESULTS=TESTGRID(GRIDTYPE,D,N) returns the results for the
%   d-dimensional grids of size Nx...xN (N can be a vector).
%   RESULTS=TESTGRID(GRIDTYPE,D,N,TRUE) also prints the results in latex
%   format.
% Make sure the batch program works for a small test graph.

if (nargin < 4)
    print = false;
end

i = 0;
for n = N
    i = i+1;
    g = Graphs.grid(gridType, n*ones(1,d), varargin{:});
    %[r, dummy1, dummy2] =  Solvers.runSolvers('graph', g, 'solvers', {'lamg', 'lamgFlat'}, 'print', false, varargin{:});
    [r, dummy1, dummy2] =  Solvers.runSolvers('graph', g, 'solvers', {'lamg'}, 'print', false, varargin{:});
    if (i == 1)
        results = r;
    else
        results.appendAll(r);
    end
end
if (print)
    p = latexPrinter(results);
    p.run();
end
end
