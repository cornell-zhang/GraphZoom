classdef (Hidden, Sealed) ReaderUf < graph.reader.Reader
    %UFLOADER Loads graph problem from the UF Collection.
    %   This interface loads a GRAPH instance from the University of
    %   Florida Sparse Matrix Collection.
    %
    %   See also: LOADER, GRAPH.
    
    %=========================== PROPERTIES ==============================
    properties (Constant, GetAccess = private)
        logger = core.logging.Logger.getInstance('graph.reader.ReaderUf')
    end
    
    properties (GetAccess = public, SetAccess = private)
        ufIndex         % UF Collection index
    end
    
    %=========================== CONSTRUCTORS ============================
    methods
        function obj = ReaderUf(ufIndex)
            %Grid constructor.
            obj.ufIndex = ufIndex;
        end
    end
    
    %======================== IMPL: Loader ============================
    methods
        function metadata = readAdditionalMetadata(obj, metadata)
            % Populate additional meta data in our metadata object from
            % the UF index.
            id = metadata.id;
            metadata.numNodes   = obj.ufIndex.nrows(id);
            metadata.numEdges   = obj.ufIndex.nnz(id);
            group               = obj.ufIndex.Group(id);
            metadata.group      = ['uf/' group{1}];
            name                = obj.ufIndex.Name(id);
            metadata.name       = name{1};
        end
        
        function g = read(obj, metadata)
            % Read a UF graph instance. Only the id field is required here,
            % and interpreted as the UF problem id to load.
            
            if (obj.logger.traceEnabled)
                obj.logger.trace('Loading UF problem id %d\n', metadata.id);
            end
            problem = ufget(metadata.id, obj.ufIndex);
            
            % Copy metadata from the Uf problem to our attribute map
            metadata.description    = problem.title;
            graph.reader.ReaderUf.copyFields(metadata.attributes, problem, ...
                {'kind', 'aux', 'date', 'author', 'ed', 'notes'});
            
            if (~isempty(strfind(problem.kind, 'undirected')))
                % Truncate A to upper-triangular part (via our Graph class
                % constructor conventions)
                metadata.graphType  = graph.api.GraphType.UNDIRECTED;
            else
                metadata.graphType  = graph.api.GraphType.DIRECTED;
            end
            
            % Check if d-D node coordinates are available; create graph
            % instance
            if (isfield(problem, 'aux') && isfield(problem.aux, 'coord'))
                coord = problem.aux.coord;
            else
                coord = [];
            end
            % Only real-valued matrices are supported for now. For
            % non-symmetric matrices, use the symmetric part.
            if (isreal(problem.A))
                A = problem.A;
            else
                A = real(problem.A);
            end
            %A = 0.5*(A+A'); % Taken care of by Graph constructor
            g = graph.api.Graph.newInstanceFromMetadata(metadata, 'adjacency', A, coord);
        end
    end
    
    %======================== PRIVATE METHODS =========================
    methods (Static, Access = private)
        function copyFields(attributes, problem, fields)
            % Copy an attribute from the Uf problem to our attribute map.
            for f = fields
                field = f{1};
                if (isfield(problem, field))
                    attributes.(field) = problem.(field);
                end
            end
        end
    end
    
end
