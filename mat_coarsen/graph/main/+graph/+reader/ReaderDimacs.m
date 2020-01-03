classdef (Hidden, Sealed) ReaderDimacs < graph.reader.Reader
    %READERDIMACS Readers graph problem from a file in the DIMACS challenge
    %format.
    %   This interface reads a GRAPH instance from a DIMACS input file.
    %
    %   Both weighted and unweighted graphs are supported; the graph type
    %   is automatically inferred from the file format: if edge lines have
    %   the format "e u v", then all weights are set to 1; if it is "e u v
    %   w", the weight of the edge (u,v) is w.
    %
    %   See also: LOADER, GRAPH.
    
    %=========================== PROPERTIES ==============================
    properties (Constant, GetAccess = private)
        logger = core.logging.Logger.getInstance('graph.reader.ReaderChaco')
    end
    
    %======================== IMPL: Reader ===============================
    methods
        function metadata = readAdditionalMetadata(obj, metadata)
            % Read additional meta data from a Chaco file f and update the
            % metadata object accordingly.
            
            % Read comments and problem line
            metadata.description = '';
            commentLineDelim = '|'; %char(10); % Comment line delimiter
            try
                f = fopen(metadata.file, 'r');
                while ~feof(f)
                    line = fgets(f);
                    
                    if (strncmp(line, 'c ', 2))
                        % Read comment lines above the problem line and
                        % store as the problem's description (except the
                        % file line)
                        comment     = strtrim(line(3:end));
                        toLower     = lower(comment);
                        addComment  = true;
                        if (isempty(comment) || ~isempty(strfind(toLower, 'file:')))
                            addComment = false;
                        elseif (strncmp(toLower, 'description:', length('description:')))
                            comment = comment(length('description:')+1:end);
                        end
                        if (addComment)
                            metadata.description = [metadata.description commentLineDelim comment];
                        end
                    elseif (strncmp(line, 'n ', 2))
                        % Node descriptor DIMACS line
                        [id, type] = strread(line,'%*s %d %s');
                        type = type{1};
                        switch (type)
                            case 's',
                                metadata.attributes.source = id;
                            case 't',
                                metadata.attributes.sink = id;
                            otherwise
                                if (obj.logger.warnEnabled)
                                    obj.logger.warn('Unrecognized node descriptor ''%s''', type);
                                end
                        end
                    elseif (strncmp(line, 'p ', 2) || strncmp(line, 'd ', 2))
                        % Standard DIMACS problem line or Ilya Safro's
                        % problem line. 
                        params = sscanf(line, '%*s %*s %d %d');
                        [metadata.numNodes, metadata.numEdges] = deal(params(1), params(2));
                    elseif (strncmp(line, 'a ', 2) || strncmp(line, 'e ', 2))
                        % ----------------------------------------------
                        % Assuming this is the beginning of the data
                        % ----------------------------------------------
                        break;
                    end
                end
                fclose(f);
                % Remove delimiter before first comment line
                metadata.description = regexprep(metadata.description, ['\' commentLineDelim], '', 'once');
            catch e
                % Gracefully close files and propagate exception
                closeFile(f);
                throw(e);
            end
        end
        
        function g = read(obj, metadata)
            % Read a GRAPH instance from metadata.file.
            
            if (obj.logger.traceEnabled)
                obj.logger.trace('Reading DIMACS problem from file %s\n', metadata.file);
            end
            
            % Set metadata fields
            metadata.graphType  = graph.api.GraphType.UNDIRECTED;
            
            % Determine graph type
            [weighted, headerLines] = isWeighted(obj, metadata.file);
            
            % Read edge data
            [u, v, weights] = obj.readEdgeData(metadata, weighted, headerLines);
            
            % Create graph instance
            A = sparse(double(u), double(v), weights, ...
                metadata.numNodes, metadata.numNodes);
            g = graph.api.Graph.newInstanceFromMetadata(metadata, 'adjacency', A, []);
        end
    end
    
    %======================== PRIVATE METHODS ============================
    methods (Access = private)
        function [weighted, headerLines] = isWeighted(obj, fileName) %#ok<MANU>
            % Find out whether this is a weighted or unweighted graph. Also
            % returns the number of header lines.
            try
                headerLines = 0;
                f = fopen(fileName, 'r');
                while ~feof(f)
                    line = fgets(f);
                    if (strncmp(line, 'e', 1) || strncmp(line, 'a', 1))
                        % Parse first edge/arc line. If it's "a|e u v", it's
                        % unweighted; otherwise, weighted.
                        header = textscan(line, '%s');
                        numTokens = numel(header{1});
                        if (numTokens == 3)
                            weighted = false;
                        elseif (numTokens == 4)
                            weighted = true;
                        else
                            error('MATLAB:ReaderDimacs:read:InputArg', 'First edge line ''%s'' is not an acceptable format', header);
                        end
                        break;
                    end
                    headerLines = headerLines+1;
                end
                fclose(f);
            catch e
                % Gracefully close files and propagate exception
                closeFile(f);
                throw(e);
            end
        end
        
        function [u, v, weights] = readEdgeData(obj, metadata, weighted, headerLines) %#ok<MANU>
            % Read edge data (u,v,weights) from the file FILENAME.
            try
                f = fopen(metadata.file, 'r');
                if (weighted)
                    data = textscan(f, '%*s %d %d %d', 'Headerlines', headerLines);
                    weights = double(data{3});
                else
                    data = textscan(f, '%*s %d %d', 'Headerlines', headerLines);
                    weights = ones(numel(data{1}), 1);
                end
                u = data{1};
                v = data{2};
                fclose(f);
            catch e
                % Gracefully close files and propagate exception
                closeFile(f);
                throw(e);
            end
        end
    end
end
