classdef (Enumeration) GraphType < int8
    %GRAPHTYPE Graph types.
    %   This is an enumeration of supported graph types. Useful for
    %   plotting and specializing class Graph.
    %
    %   See also: GRAPH, GRAPHPLOTTER.
    
    enumeration
        DIRECTED(0)
        UNDIRECTED(1)
    end
end
