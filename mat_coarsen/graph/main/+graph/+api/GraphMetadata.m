classdef (Sealed) GraphMetadata < handle
    %GRAPHMETADATA A graph problem meta data struct.
    %   Includes all meta data attributes of a graph problem. In
    %   particular, stores the information required to load the actual
    %   graph data, and caches descriptive statistics (e.g. number of
    %   nodes, number of edges).
    %
    %   See also: GRAPH.
    
    %======================== MEMBERS =================================
    properties
        %-------------------------
        % Descriptive statistics
        %-------------------------
        numNodes                                % # graph nodes
        numEdges                                % # graph edges = #non-zeros in the adjacency matrix
        attributes = struct()                   % Additional key-value pairs provided by the source
        
        %-------------------------
        % Source information
        %-------------------------
        group                                   % Problem group name/directory/collection (mandatory)
        id = -1                                 % Unique problem positive integer identifier within the source (optional; mandatory if file is missing)
        file = 'none'                           % File name to load problem from (optional; mandatory if id is missing)
        
        %-------------------------
        % Descriptive meta data
        %-------------------------
        name                                    % Problem name
        description                             % Title/short description of the problem
        graphType                               % Directed/undirected (mandatory)
        formatType                              % Input format (mandatory)
    end
    
    properties (Dependent)
        key
    end
    
    %======================== CONSTRUCTORS ============================
    methods (Static)
        function obj = copy(other)
            % Copy c-tor. Copies all fields except attributes.
            obj = graph.api.GraphMetadata();
            obj.numNodes = other.numNodes;
            obj.numEdges = other.numEdges;
            %attributes = struct(other.attributes); % Attributes NOT copied
            %over
            
            obj.group = other.group;
            obj.id = other.id;
            obj.file = other.file;
            obj.name = other.name;
            obj.description = other.description;
            obj.graphType = other.graphType;
            obj.formatType = other.formatType;
        end
    end
    
    %======================== GET & SET ===============================
    methods
        function code = get.key(obj)
            % A unique identifier of this object.
            code = sprintf('%s/%s', char(obj.group), obj.name);
        end
    end
    
    %======================== METHODS =================================
    methods
        function s = toString(obj)
            % A textual representation of this object.
            s = sprintf('%s/', char(obj.group));
            if (~isempty(obj.name))
                s = [s sprintf('%s', obj.name)];
            elseif (obj.id > 0)
                s = [s sprintf('%d', obj.id)];
            end
        end
    end
    
end
