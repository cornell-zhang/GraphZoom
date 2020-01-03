classdef (Hidden, Sealed) ReaderGenerated < graph.reader.Reader
    %READERMAT A dummy reader of a generated graph problem.
    %   This interface allows using a prepared GRAPH instance in a reader.
    %   Assumes that the graph is stored in its metadata's attribute "g".
    %
    %   See also: READER, GRAPH.
    
    %=========================== PROPERTIES ==============================
    properties (Constant, GetAccess = private)
        logger = core.logging.Logger.getInstance('graph.reader.ReaderGenerated')
    end
    
    %======================== IMPL: Reader ============================
    methods
        function g = read(obj, metadata) %#ok<MANU>
            % Read a graph instance from metadata.attributes.
            
            g = metadata.attributes.g;
        end
    end
    
end
