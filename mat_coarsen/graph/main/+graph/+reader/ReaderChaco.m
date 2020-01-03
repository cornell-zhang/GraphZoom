classdef (Hidden, Sealed) ReaderChaco < graph.reader.Reader
    %READERCHACO Readers graph problem from a file in Chaco format.
    %   This interface reads a GRAPH instance from an input file. Only the
    %   simplest Chaco format (undirected unweighted graphs, zero node
    %   weights) is currently supported.
    %
    %       <numNodes> <numEdges>
    %
    %       N11 .. N1,k1   <!-- neighboring node indices of node 1 -->
    %
    %       ...
    %
    %       Nn1 .. Nn,kn   <!-- neighboring node indices of node n -->
    %
    %   See also: LOADER, GRAPH.
    
    %=========================== PROPERTIES ==============================
    properties (Constant, GetAccess = private)
        logger = core.logging.Logger.getInstance('graph.reader.ReaderChaco')
    end
    
    %======================== IMPL: Loader ============================
    methods
        function metadata = readAdditionalMetadata(obj, metadata) %#ok<MANU>
            % Read additional meta data from a Chaco file f and update the
            % metadata object accordingly.
            
            % Read header line
            try
                f = fopen(metadata.file, 'r');
                line = fgets(f);
                header = textscan(line, '%d');
                header = header{1};
                if (numel(header) ~= 2)
                    error('Unsupported Chaco file format. Only simplest format supported with 2 parameters in header line (numNodes, numEdges)');
                end
                fclose(f);
            catch e
                % Gracefully close files and propagate exception
                closeFile(f);
                throw(e);
            end
            [metadata.numNodes, metadata.numEdges] = deal(double(header(1)), double(header(2)));
        end
        
        function g = read(obj, metadata)
            % Read a GRAPH instance from metadata.file.
            
            if (obj.logger.traceEnabled)
                obj.logger.trace('Reading Chaco problem from file %s\n', metadata.file);
            end
            
            % Set metadata fields
            metadata.graphType  = graph.api.GraphType.UNDIRECTED;
            
            try
                % Load graph data
                f = fopen(metadata.file, 'r');
                % Ignore header line, already read it into metadata at this
                % stage
                fgets(f);
                if (obj.logger.traceEnabled)
                    obj.logger.trace('Size: #nodes %d, #edges %d\n', metadata.numNodes, metadata.numEdges);
                end
                data    = textscan(f, '%d');
                data    = double(data{1});
                fclose(f);
                
                f = fopen(metadata.file, 'r');
                % Ignore header line
                fgets(f);
                % Parse how many spaces there are per row = #non-zeros per row
                %             rows    = textscan(f, '%[^\n]'); fclose(f);
                %
                %             rows    = rows{1}; %rowNz   =
                %             cell2mat(cellfun(@(x)(numel(strread(x, '%d',
                %             'delimiter', ' '))), rows, 'UniformOutput',
                %             false)); %rowNz   =
                %             cell2mat(cellfun(@(x)(numel(regexpi(x, ' '))),
                %             rows, 'UniformOutput', false)); rowNz   =
                %             cell2mat(cellfun(@graph.reader.numEntities, rows,
                %             'UniformOutput', false)); rowNz   = [1; rowNz];
                %            indices = cumsum(rowNz);
                
                % Allocate and populate the first column in the
                % compressed-column non-zero list (denoted nzList here) We read
                % line-by-line and ignore empty lines, which is hard to do with
                % a one-call textscan on the entire file f.
                nzList  = zeros(2*metadata.numEdges, 1);
                index = 1;
                for i = 1:metadata.numNodes
                    s = strtrim(fgets(f));
                    if (~isempty(s))
                        numNeighbors = graph.reader.numEntities(s);
                        nzList(index:index+numNeighbors-1) = i;
                        index = index + numNeighbors;
                    end
                    %nzList(indices(i):indices(i+1)-1) = i;
                end
                fclose(f);
                
                % Create graph instance
                A = sparse(nzList, data, ones(2*metadata.numEdges,1), ...
                    metadata.numNodes, metadata.numNodes);
                g = graph.api.Graph.newInstanceFromMetadata(metadata, A);
            catch e
                % Gracefully close files and propagate exception
                closeFile(f);
                throw(e);
            end
        end
    end
end
