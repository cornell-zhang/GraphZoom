classdef (Hidden, Sealed) ReaderMat < graph.reader.Reader
    %READERMAT Reads a graph problem from a MATLAB MAT file.
    %   This interface reads a GRAPH instance from a MAT file that contains
    %   the graph metadata object and adjacency matrix.
    %
    %   See also: READER, GRAPH.
    
    %=========================== PROPERTIES ==============================
    properties (Constant, GetAccess = private)
        logger = core.logging.Logger.getInstance('graph.reader.ReaderMat')
    end
    
    %======================== IMPL: Reader ============================
    methods
        function metadata = readAdditionalMetadata(obj, metadata)
            % Read a graph metadata object from the MAT file metadata.file.
            tStart = tic;
            originalFile = metadata.file;
            data = load(metadata.file, 'metadata');
            elapsed = toc(tStart);
            if (obj.logger.traceEnabled)
                obj.logger.trace('Loading metadata took %.6f seconds\n', elapsed);
            end
            metadata = data.metadata;
            if (isfield(metadata.attributes, 'g'))
                obj.logger.warn('Found metadata.attributes.g: %s\n', metadata.key);
            end
            
            % Make sure that the final MAT file name is the file system
            % resource passed to addInstanceFromFile(), NOT the original
            % one that may be loaded from the MAT file metadata -variable-.
            if (~isempty(originalFile))
                metadata.file = originalFile;
            end
        end
        
        function g = read(obj, metadata) %#ok<MANU>
            % Read a graph instance from metadata.file.
            
            % Read all variables (metadata, A; optional: coord)
            data = load(metadata.file);

            if (~isfield(data, 'A'))
                obj.logger.warn('Matrix A is not present in input file %s\n', metadata.file);
                g = [];
                return;
            end
            % Create graph instance
            if (isfield(data, 'coord'))
                coord = data.coord;
            else
                coord = [];
            end
            g = graph.api.Graph.newInstanceFromMetadata(data.metadata, 'adjacency', data.A, coord);
        end
    end
    
end
