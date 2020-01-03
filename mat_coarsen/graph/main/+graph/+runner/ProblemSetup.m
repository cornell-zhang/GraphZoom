classdef ProblemSetup < handle
    %PROBLEMSETUP Constructs a graph-related problem.
    %   This interface builds a Problem class that represents the
    %   computational graph problem at hand. The problem also serves as the
    %   back-bone of the finest level in a multi-level hierarchy.
    %
    %   See also: PROBLEM, LEVEL, PROBLEMSETUPLAPLACIAN.
    
    %======================== METHODS =================================
    methods (Abstract)
        problem = build(obj, g, options, args)
        % Build the finest level problem for the graph G.
    end
end
