classdef (Hidden, Sealed) ReaderCompressedColumn < graph.reader.Reader
    %READERMAT Reads a graph problem from a MATLAB MAT file.
    %   This interface reads a GRAPH instance from a compressed-column-format text file that contains
    %   the graph metadata object and adjacency matrix.
    %
    %   See also: READER, GRAPH.
    
    %=========================== PROPERTIES ==============================
    properties (Constant, GetAccess = private)
        logger = core.logging.Logger.getInstance('graph.reader.ReaderCompressedColumn')
    end
    
    %======================== IMPL: Reader ============================
    methods
        function metadata = readAdditionalMetadata(obj, metadata) %#ok<MANU>
            % Read a graph metadata object from the file metadata.file.

            A = spconvert(load(metadata.file));
            metadata.graphType = graph.api.GraphType.UNDIRECTED;
            metadata.numNodes = size(A,1);
            metadata.numEdges = numel(nonzeros(A));
            metadata.attributes.A = A;
            % Unsupported yet
        end
        
        function g = read(obj, metadata) %#ok<MANU>
            % Read a graph instance from metadata.file.
            
            % Read all variables (metadata, A; optional: coord)
            A = metadata.attributes.A;
            metadata.attributes.A = [];
            g = graph.api.Graph.newInstanceFromMetadata(metadata, A);
        end
    end
    
end
