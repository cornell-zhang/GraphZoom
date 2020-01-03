classdef (Sealed) GraphUtil < handle
    %GRAPHUTIL Graph utilities.
    %   This is a utility class containing useful static methods related to
    %   Graphs.
    %
    %   See also: GRAPH, GRAPHFORMAT.
    
    %======================== PROPERTIES ==============================
    properties (Constant, GetAccess = private)
        fileExtensionToGraphFormat = containers.Map();
    end
    
    %=========================== CONSTRUCTORS ============================
    methods (Access = private)
        function obj = GraphUtil
            %Hide constructor in utility class.
        end
    end
    
    %======================== METHODS =================================
    methods (Static)
        function graphFormat = toGraphFormat(fileExtension)
            % Convert a file extension to the corresponding graph format
            % enumerated constant.
            map = graph.api.GraphUtil.fileExtensionToGraphFormat;
            if (map.isempty)
                map('mat')      = graph.api.GraphFormat.MAT;
                map('chaco') 	= graph.api.GraphFormat.CHACO;
                map('dimacs')   = graph.api.GraphFormat.DIMACS;
                map('txt')      = graph.api.GraphFormat.COMPRESSED_COLUMN;
            end
            if (map.isKey(fileExtension))
                graphFormat = map(fileExtension);
            else
                graphFormat = [];
            end
        end
        
        function smallGraphs = getGraphsWithEdgesBetween(batchReader, minEdges, maxEdges)
            % Return the indices of all graphs with minEdges <= numEdges <= maxEdges in a
            % batch reader and sort them by ascending numEdges.
            numEdges = batchReader.getNumEdges;
            [sorted, smallGraphs] = sort(numEdges);
            smallGraphs = smallGraphs((sorted >= minEdges) & (sorted <= maxEdges));
        end
    end
end
