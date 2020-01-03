function mem = sparseFun(A)
%SPARSEFUN Tests passing a sparse matrix parameter by reference.
%   Pass a large enough matrix (e.g. from the UF collection: problem =
%   ufget(2318); A = problem.A).  Verify that the return value is the same
%   as the available memory value before calling this method.
%
%   See also: MEMORY.

% Do some operation of A
class(A);

% Return available memory
memView = memory;
mem     = memView.MemAvailableAllArrays;

end

