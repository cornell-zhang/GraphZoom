%LOWDEGREESWEEP Low-degree node scanning.
%   VISITED=LOWDEGREESWEEP(VISITED,A,CANDIDATE,MAXDEGREE) sweeps over the
%   node subset (row vector) CANDIDATE of the undirected graph whose
%   symmetric adjacency matrix is A, and marks an independent set F nodes
%   of degree <= MAXDEGERE. Note: A must have a zero diagonal, or this
%   function will return wrong values or even run indefinitely.
%
%   The input VISITED array must have 0 values at CANDIDATE nodes.
%
%   Upon returning from this function, the VISITED flag array is updated
%   according to the following coding scheme:
%
%   LOW_DEGREE      = 1     Low-degree nodes (F) 
%
%   NOT_ELIMINATED  = 4     High or low degree; not in F to satisfy F's
%                           independence
%
%   see also: LOWDEGREENODES.
