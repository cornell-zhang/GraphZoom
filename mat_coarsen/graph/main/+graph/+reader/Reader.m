classdef Reader < handle
    %READER Read a graph problem from an input source.
    %   This interface reads a GRAPH instance from a source.
    %
    %   See also: GRAPH, READERFACTORY.
    
    %======================== METHODS =================================
    methods
        function metadata = readAdditionalMetadata(obj, metadata) %#ok<MANU>
            % Read additional meta data from the input source specified by
            % metadata and update the metadata object accordingly. A stub.
        end
    end
    
    methods (Abstract)
        graph = read(obj, metadata)
        % Read a GRAPH instance from the data source specified by the
        % METADATA struct of type GraphMetadata.
    end
    
end
