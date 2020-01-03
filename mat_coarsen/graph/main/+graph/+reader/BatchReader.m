classdef (Sealed) BatchReader < handle
    %BATCHREADER Loads a set of graph problems.
    %   This is the main public API class of this package for reading graph
    %   instances. This is a builder that supports adding metadata objects
    %   of various data sources first, and separately load the
    %   corresponding full graph instances using read().
    %
    %   See also: LOADER, GRAPH, BATCHERUNNER.
    
    %=========================== PROPERTIES ==============================
    properties (Constant, GetAccess = private)
        logger = core.logging.Logger.getInstance('graph.reader.BatchReader')
    end
    
    properties (GetAccess = private, SetAccess = private)
        readerFactory           % Graph instance reader factory (for all input formats)
        problems                % List of of graph meta data; populated by Readers and then used to read graphs
    end
    properties (Dependent)
        size                    % Number of graphs readed into this object
    end
    
    %=========================== CONSTRUCTORS ============================
    methods
        function obj = BatchReader
            %Batch reader constructor. Initializes internal readers.
            obj.readerFactory   = graph.reader.ReaderFactory;
        end
    end
    
    %======================== GET & SET ===============================
    methods
        function sz = get.size(obj)
            sz = numel(obj.problems);
        end
    end
    
    %======================== METHODS =================================
    methods
        function add(obj, varargin)
            % Add an instance with group GROUP and input format FORMATTYPE.
            % VARARGIN contains additional arguments that identify the
            % instance within the group and format type (id/graph
            % type/input dir/input file name).
            
            args = graph.reader.BatchReader.parseArgs(varargin{:});
            
            % Argument validation rules
            if (isempty(args.formatType))
                % Automatic format detection of a non-UF format
                if (~isempty(args.graph))
                    % Generated graph, dummy reader
                    args.graph.metadata.attributes.g = args.graph;
                    obj.addInstance(args.graph.metadata, 'generated', graph.api.GraphFormat.GENERATED);
                elseif (~isempty(args.dir))
                    obj.addInstancesFromDir(args.dir, args.extension);
                else
                    obj.addInstanceFromFile(args.group, args.file);
                end
            else
                switch (args.formatType)
                    case graph.api.GraphFormat.UF,
                        % UF format
                        if (~isempty(args.id))
                            obj.addUfInstancesWithId(args.id);
                        else
                            obj.addUfInstancesWithType(args.type, args.keywords);
                        end
                    otherwise
                        error('MATLAB:BatchReader:add', 'Input format ''%s'' should not be explicitly specified; it is auto-detected using file extensions', char(args.formatType));
                end
            end
            
        end
        
        function removeIndex(obj, i)
            % Remove the instance number i on the problem list.
            obj.problems(i) = [];
        end
        
        function removeMetadata(obj, metadata)
            % Remove all instances identified by the metadata argument from
            % the problem list.
            key = metadata.key;
            found = [];
            for i = 1:numel(obj.problems)
                if (strcmp(obj.problems{i}.key, key))
                    found = [found i]; %#ok
                end
            end
            obj.problems(found) = [];
        end
        
        function metadata = getMetadata(obj, i)
            % Get meta data of graph instance number i on the problem list.
            metadata = obj.problems{i};
        end
        
        function numNodes = getNumNodes(obj)
            % A view of the problem list - returns the number of nodes of
            % each instance.
            if (obj.size == 0)
                numNodes = [];
            else
                numNodes = obj.getMetaData('numNodes');
            end
        end
        
        function numEdges = getNumEdges(obj)
            % A view of the problem list - returns the number of edges of
            % each instance.
            if (obj.size == 0)
                numEdges = [];
            else
                numEdges = obj.getMetaData('numEdges');
            end
        end
        
        function value = getMetaData(obj, field)
            % A view of the problem list - returns the value of the
            % metadata field FIELD for each instance in a cell array.
            if (any(strcmp(field, {'numNodes', 'numEdges', 'id'})))
                % Numeric field
                value = cellfun(@(v)(v.(field)), obj.problems);
            else
                % Non-numeric field
                value = cellfun(@(v)(v.(field)), obj.problems, 'UniformOutput', false);
            end
        end
        
        function index = fieldMatches(obj, field, regex)
            % Return a logical array indicating whether each problem's
            % metadata FIELD value matches the regular expression REGEX.
            index = cellfun(@(x)(~isempty(x)), regexp(obj.getMetaData(field), regex));
        end
        
        function g = read(obj, i)
            % Fully load a graph instance number i on the problem list.
            metadata    = obj.problems{i};
            reader      = obj.readerFactory.newInstance(metadata.formatType);
            g           = reader.read(metadata);
        end
    end
    
    %======================== METHODS =================================
    methods (Static, Access = private)
        function args = parseArgs(varargin)
            % Parse input arguments to the add() method.
            p                   = inputParser;
            p.FunctionName      = 'BatchReader';
            p.KeepUnmatched     = true;
            p.StructExpand      = true;
            
            p.addParamValue('formatType', [], @(x)(isa(x,'graph.api.GraphFormat')));
            p.addParamValue('id', [], @isnumeric);
            p.addParamValue('group', [], @(x)(isempty(x) || ischar(x)));
            p.addParamValue('type', [], @(x)isa(x,'graph.api.GraphType'));
            p.addParamValue('keywords', [], @iscell);
            p.addParamValue('dir', [], @ischar);
            p.addParamValue('file', [], @ischar);
            p.addParamValue('extension', [], @ischar);
            p.addParamValue('graph', [], @(x)isa(x,'graph.api.Graph'));
            
            p.parse(varargin{:});
            args = p.Results;
            
            if (args.formatType == graph.api.GraphFormat.UF)
                if  (~xor(isempty(args.id), isempty(args.keywords) && isempty(args.type)))
                    error('MATLAB:BatchReader:parseArgs', 'Must specify either an id or UF problem kind keywords or graph type for UF instances');
                end
            else
                if (~isempty(args.formatType))
                    error('MATLAB:BatchReader:parseArgs', 'The input format ''%s'' is auto-detected and should not be explicitly specified', char(args.formatType));
                end
                if (~isempty(args.graph))
                    % OK, generated graph
                elseif (isempty(args.dir))
                    if (~isempty(args.extension))
                        error('MATLAB:BatchReader:parseArgs', 'Must only specify a file extension if a directory is specified for non-UF instances');
                    end
                    if (numTrue([isempty(args.file), isempty(args.group)]) ~= 0)
                        error('MATLAB:BatchReader:parseArgs', 'Must specify both a group and a file if a directory is not specified for non-UF instances');
                    end
                else
                    if (~isempty(args.file))
                        error('MATLAB:BatchReader:parseArgs', 'If a directory is specified, must not specify a file');
                    end
                end
            end
        end
    end
    
    methods (Access = private)
        function addInstance(obj, metadata, group, formatType)
            % Add a graph metadata to the map. Set the graph input format
            % type to FORMATTYPE and group to GROUP.
            metadata.group      = group;
            metadata.formatType = formatType;
            if (obj.logger.traceEnabled)
                obj.logger.trace('Adding problem %s\n', metadata.toString);
            end
            
            % Complete reading the metadata object and store in problems map
            reader = obj.readerFactory.newInstance(metadata.formatType);
            try
                metadata = reader.readAdditionalMetadata(metadata);
                %obj.problems(metadata.key) = metadata;
                obj.problems = [obj.problems {metadata}];
            catch e
                if (obj.logger.infoEnabled)
                    obj.logger.info('Failed to add problem %s: %s\n', metadata.toString, e.message);
                end
            end
        end
        
        function addUfInstancesWithId(obj, ufId)
            % Add a UF collection instances with UF IDs ufId.
            if (size(ufId, 1) > 1)
                ufId = ufId';
            end
            for id = ufId
                metadata            = graph.api.GraphMetadata;
                metadata.id         = id;
                obj.addInstance(metadata, 'uf', graph.api.GraphFormat.UF);
            end
        end
        
        function addUfInstancesWithType(obj, graphType, keywords)
            % Add all UF collection real symmetric instances whose kind
            % contains all of the keywords.
            
            ufIndex = ufget;
            if (~isempty(graphType))
                % Include ALL square matrices. Filter undirected graphs in
                % Graph cnstructor instead.
                matches = find(ufIndex.nrows == ufIndex.ncols);
            end
            if (~isempty(keywords))
                matches = intersect(matches, uffind('kind', keywords{:}));
            end
            [dummy, j]  = sort(ufIndex.nrows(matches)); %#ok
            clear dummy;
            matches = matches(j);
            
            obj.addUfInstancesWithId(matches);
            if (obj.logger.traceEnabled)
                obj.logger.trace('Added %d UF problems\n', numel(matches));
            end
        end
        
        function addInstanceFromFile(obj, group, fullPath)
            % Add a graph instance from the file FULLPATH in the format
            % FORMATTYPE.
            [dummy, fileName, fileExtension] = fileparts(fullPath); %#ok
            fileExtension       = fileExtension(2:end); % Strip trailing dot
            metadata            = graph.api.GraphMetadata;
            metadata.name       = fileName;
            metadata.file       = fullPath;
            formatType          = graph.api.GraphUtil.toGraphFormat(fileExtension);
            if (isempty(formatType))
                if (obj.logger.traceEnabled)
                    obj.logger.trace('Skipping file %s: unsupported file extension ''%s''\n', ...
                        fullPath, fileExtension);
                end
            else
                obj.addInstance(metadata, group, formatType);
            end
        end
        
        function addInstancesFromDir(obj, directory, extension)
            % Main dir load call: load all non-dot files under the
            % directory DIR. Recurse to sub-directories. Instance group set
            % by convention to the directory name.
            if (nargin < 4)
                extension = '';
            end
            [dummy, group] = fileparts(directory); %#ok
            clear dummy;
            obj.addInstancesFromDirRecursive(group, directory, extension);
        end
        
        function addInstancesFromDirRecursive(obj, group, directory, extension)
            % Load all non-dot files under the directory DIR. Recurse to
            % sub-directories.
            if (obj.logger.debugEnabled)
                obj.logger.debug('Looking for instances in ''%s''\n', directory);
            end
            d = dir(directory);
            for i = 1:numel(d)
                fileName                = d(i).name;
                [dummy1, dummy2, fileExtension]	= fileparts(fileName); %#ok
                clear dummy1 dummy2;
                fileExtension           = fileExtension(2:end); % Strip trailing dot
                isDotFile               = strncmp(fileName, '.', 1);
                % Skip dot files
                if (~isDotFile)
                    fullPath = [directory '/' fileName];
                    if (d(i).isdir)
                        % Recurse to sub-directory fileName
                        obj.addInstancesFromDirRecursive([group '/' fileName], fullPath, extension);
                    elseif (isempty(extension) || strcmp(extension, fileExtension))
                        % fileName = file directly under this directory
                        % that matches the extension, load it
                        obj.addInstanceFromFile(group, fullPath);
                    end
                end
            end
        end
    end
end
