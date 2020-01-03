classdef (Sealed) Graph < handle
    %GRAPH A weighted directed graph (network) data structure.
    %   This class represents an immutable weighted undirected graph
    %   G=(V,E) with nodes V and edges E between them. Each edge (u,v) has
    %   an associated positive weight C(u,v).
    %
    %   We assume that nodes are not self-connected, and that there are no
    %   double edges (i.e. if (u,v) is an edge, then (v,u) is not).
    %   Therefore this class models both such direct graphs and undirect
    %   graphs with fixed edge orientations.
    %
    %   See also: GRAPHPLOTTER, GRAPHLOADER.
    
    %=========================== PROPERTIES ==============================
    properties (GetAccess = public, SetAccess = public)
        coord               % Optional d-D node locations for graph drawing
    end
    properties (Dependent)
        numNodes            % # nodes
        numEdges            % # edges
        edge                % Edge list (u,v,edgeId). edgeId is a running ID from 1 to numEdges
        edgesAndWeights     % Edge + weight list (u,v,w(u,v))
%        weight              % Edge weight list (w)
%        weightMatrix        % Edge weight matrix (diag(w))
%        incidence           % Incidence matrix
    end
    properties (GetAccess = public, SetAccess = private)
        metadata            % Data about this graph
        
        % Cached dependent properties
%        adjacency           % Undirected adjacency matrix. Always upper-diagonal.
        adjacency        % Symmetrized adjacency matrix (adjacency+adjacency')
        degree              % Node degree list
        laplacian           % Laplacian matrix
        sdd                 % An SDD system associated with the graph
        mass                % Laplacian diagonal mass matrix
%       orientation         % Conventional edge orientation matrix
%        edgeIndex           % Symmetrized matrix with adjacency matrix non-zero pattern. Entry(i,j) = row index of this edge in the obj.edge list
    end
    
    %=========================== CONSTRUCTORS ============================
    methods (Access = private)
        function obj = Graph(metadata, dataType, data, coord)
            %Graph Constructor.
            %   Graph(metadata, A, coord) constructs a graph with specified
            %   metadata, symmetric adjacency matrix with no diagonal, and
            %   optional d-D node locations for graph drawing.
            %
            %   If A is empty, it is ignored.

            % Read adjacency matrix
            switch (dataType)
                case 'sym-adjacency',
                    % Symmetric adjacency matrix
                    A          = data;
                case 'adjacency',
                    % data = upper-triangular part of the adjacency matrix.
                    % Symmetrize and remove diagonal.
                    W           = triu(data,1);
                    A           = W + W'; % Seems to be slightly faster than max(W,W')
                case 'edge-list',
                    % data is a matrix whose row format is assumed to be [i
                    % j aij].
                    maxData     = max(data, [], 1);
                    numNodes    = max(maxData(:,1:2));
                    W           = sparse(data(:,1), data(:,2), data(:,3), numNodes, numNodes);
                    A           = W + W'; %0.5*(W + W'); % Seems to be slightly faster than max(W,W')
                case {'laplacian', 'sdd'}
                    % data = graph Laplacian or an SDD system.
                    %A           = diag(diag(data)) - data;
                    A           = data;
                otherwise,
                    error('Unrecognized graph data type ''%s''', dataType);
            end
            
            % Store metadata
            obj.metadata            = metadata;
            metadata.graphType      = graph.api.GraphType.UNDIRECTED; % Graph is always UNDIRECTED here

            if (strcmp(dataType, 'sdd'))
                % data = SDD system
                obj.sdd = A;
            elseif (strcmp(dataType, 'laplacian'))
                % data = graph Laplacian. Assumed to be singly-connected.
                obj.coord = coord;
                obj.metadata.numNodes   = size(data,1);
                if (size(data,1) == 1)
                    obj.metadata.numEdges = 0;
                else
                    obj.metadata.numEdges   = (nnz(data)-obj.metadata.numNodes)/2; % Assuming zero diagonal!
                end
                
                % Cache matrix fields
                obj.laplacian = A;
            else
                obj.metadata.numNodes   = size(A,1);
                if (size(A,1) == 1)
                    obj.metadata.numEdges = 0;
                else
                    obj.metadata.numEdges = nnz(A)/2; % Assuming zero diagonal!
                end
                
                % Cache matrix fields
                obj.adjacency       = A;
                obj.degree          = sum(A ~= 0, 1); % Could be improved a little by MEX
            end
            
            % Read coordinates
            if (~isempty(coord) && (size(coord,1) ~= size(A,1)))
                warning('MATLAB:Graph:InputArg', 'Coordinate vector was not of size numNodes x d, ignoring');
            else
                obj.coord = coord;
            end
        end
    end
    
    % Factory methods
    methods (Static)
        function obj = newNamedInstance(name, dataType, data, coord)
            % newNamedInstance(name, numNodes, edgeData, coord)
            % constructs a named graph with the specified name, edge matrix
            % (edgeData(i,:)=(u,v,w) represents the
            %   ith edge nodes u and v, carrying weight w) and optional 2-D
            %   node locations for graph drawing.
            md              = graph.api.GraphMetadata();
            md.name         = name;
            obj             = graph.api.Graph.newInstanceFromMetadata(md, dataType, data, coord);
        end
        
        function obj = newInstanceFromMetadata(md, dataType, data, coord)
            % newNamedInstance(name, numNodes, edgeData, coord)
            % constructs a named graph with the specified name, edge matrix
            % (edgeData(i,:)=(u,v,w) represents the
            %   ith edge nodes u and v, carrying weight w) and optional 2-D
            %   node locations for graph drawing.
            obj = graph.api.Graph(md, dataType, data, coord);
        end
    end
    
    %=========================== METHODS =================================
    methods
        function g = subgraph(obj, nodes, name)
            % Return the subgraph of g containing the nodes "nodes" and
            % their links to themselves only.
            m = graph.api.GraphMetadata.copy(obj.metadata);
            m.group = [obj.metadata.group '/' obj.metadata.name];
            if (nargin < 3)
                name = 'subgraph';
            end
            m.name = name;
            m.file = [];
            if (~isempty(obj.coord))
                subCoord = obj.coord(nodes,:);
            else
                subCoord = [];
            end
            g = graph.api.Graph(m, 'adjacency', obj.adjacency(nodes,nodes), subCoord);
        end
    end
        
    %=========================== METHODS =================================
    methods
        function f = edgeFunction(obj, fdata, varargin)
            % Convert an array FDATA to an edge function F on the graph.
            % FDATA must be of length NUMEDGES. F=OBJ.EDGEFUNCTION(FDATA)
            % is a sparse matrix with the non-zero pattern of
            % OBJ.ADJACENCY. F=OBJ.EDGEFUNCTION(FDATA,
            % graph.api.GraphType.UNDIRECTED) is its symmetrized version
            % (FDATA should still be of length NUMEDGES!).
            if (nargin < 3)
                type = graph.api.GraphType.DIRECTED;
            else
                type = varargin{1};
            end
            e = obj.edge;
            f = sparse(e(:,1), e(:,2), fdata, obj.numNodes, obj.numNodes);
            if (type == graph.api.GraphType.UNDIRECTED)
                f = max(f,f');
            end
        end
        
        function Wstrong = strongAdjacency(obj, threshold)
            % Return the filtered strong connection adjacency matrix for
            % threshold THRESHOLD.
            W = obj.adjacency;
            Wstrong = filterSmallEntries(W, max(abs(W)), threshold, 'abs', 'min');% #ok
        end
        
        function r = strongEdgePortion(obj, threshold)
            % Return the percentage of strong connetions in the adjacency
            % matrix.
            r = numel(nonzeros(obj.strongAdjacency(threshold)))/numel(nonzeros(obj.adjacency));
        end
        
        function r = weakEdgePortion(obj, threshold)
            % Return the percentage of weak (small) connetions in the
            % adjacency matrix.
            r = 1 - obj.strongEdgePortion(threshold);
        end
    end
    
    %=========================== GET & SET ===============================
    methods
        function numNodes = get.numNodes(obj)
            % Return the number of graph nodes.
            numNodes = obj.metadata.numNodes;
        end
        
        function numEdges = get.numEdges(obj)
            % Return the number of graph edges.
            numEdges = obj.metadata.numEdges;
        end
        
        function edge = get.edge(obj)
            % Returns the edge list.
            [i, j]  = find(tril(obj.adjacency));
            edge    = [i j (1:obj.numEdges)'];
        end

        function edge = get.edgesAndWeights(obj)
            % Returns the edge list.
            [i, j, w]   = find(tril(obj.adjacency));
            edge        = [i j w];
        end
        
%         function weight = get.weight(obj)
%             % Returns the edge weight list.
%             weight = nonzeros(obj.adjacency);
%         end
%         
%         function W = get.weightMatrix(obj)
%             % Return the (sparse) graph edge weight matrix W = diag(w_i).
%             W = spdiags(obj.weight, 0, obj.numEdges, obj.numEdges);
%         end
%         
%         function N = get.incidence(obj)
%             % Returns the (sparse) graph incidence matrix N of size ne x
%             % nv. N(i,u)=1, N(i,v)=-1, where the ith edge's head is node u
%             % and its tail is v; N(i,j)=0 for all other nodes j.
%             ne  = obj.numEdges;
%             N   = sparse(...
%                 reshape(repmat(1:ne,[2 1]),[2*ne 1]), ...
%                 reshape(obj.edge(:,1:2)',[2*ne 1]), ...
%                 reshape([ones(ne,1) -ones(ne,1)]',[2*ne 1]) ...
%                 );
%         end
        
        function D = get.mass(obj)
            % Laplacian mass matrix.
            D = spdiags(sum(obj.adjacency,2), 0, obj.numNodes, obj.numNodes);
        end

        function A = get.adjacency(obj)
            % Return the adjacency matrix. Cached once computed.
            if (isempty(obj.adjacency))
                L = obj.laplacian;
                if (isempty(obj.laplacian))
                    error('Neither the adjacency nor the Laplacian was set, please set one of them in the graph object constructor');
                    % Laplacian row sums can be numerically small, skip
                    % this check to save time
                    % elseif (~isempty(find(sum(obj.laplacian), 1)))
                    % error('The Laplacian matrix field was set to a non-zero-row-sum matrix. While it can be used to store any matrix, it cannot be properly used to generate an adjacency matrix');
                else
                    obj.adjacency = diag(diag(L)) - L;
                    obj.degree    = sum(L ~= 0, 1) - 1; % Could be improved a little by MEX
                end
            end
            A = obj.adjacency;
        end

        function L = get.laplacian(obj)
            % Return the (sparse) graph Laplacian L = D-A. Note that L may
            % not be SPD if the weights are negative. Cached.
            if (isempty(obj.laplacian))
                A = obj.adjacency;
                D = obj.mass;
                obj.laplacian = D - A;
            end
            L = obj.laplacian;
        end
        
%         function S = get.orientation(obj)
%             % Returns an anti-symmetric #edges x #nodes sparse matrix of
%             % edge orientation signs (+-1) for an undirected graph. The
%             % orientation depends on the CSS sparse adjacency matrix
%             % storage and should not be relied on in a client.
%             if (isempty(obj.orientation))
%                 e = obj.edge;
%                 obj.orientation = spconvert([...
%                     [e(:,1) (1:obj.numEdges)'  ones(obj.numEdges,1)];...
%                     [e(:,2) (1:obj.numEdges)' -ones(obj.numEdges,1)];...
%                     [obj.numNodes obj.numEdges 0]]);
%             end
%             S = obj.orientation;
%         end
    end
    
    %=========================== PRIVATE METHODS =========================
    methods (Access = private)
    end
end
