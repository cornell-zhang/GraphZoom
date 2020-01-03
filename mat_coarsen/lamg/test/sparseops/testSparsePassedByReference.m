%TESTSPARSEPASSEDBYREFERENCE test whether a sparse matrix is passed by
%reference.
%   This is a learning test of MATLAB's memory mangagement that shows that
%   a large sparse matrix is passed by *reference* (not by value) to a
%   function.

clear all;
close all;

% Generate a large sparse matrix from the UF collection
problem = ufget(2318);
A = problem.A;

% Memory before
memView     = memory;
memBefore   = memView.MemAvailableAllArrays

% Memory after
memAfter    = sparseFun(A)

memOfPassingParameterToMethod = memAfter-memBefore
