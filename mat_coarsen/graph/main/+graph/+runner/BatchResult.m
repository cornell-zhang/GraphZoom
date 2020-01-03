classdef (Sealed) BatchResult < handle
    %BATCHRESULT Result holder of a batch run.
    %   This class holds the result of a batch run on a list of graph
    %   problems. It holds the graph metadata list of size N (=number of
    %   problems) separately from the results, which are held in an array
    %   of size NxM (M=results reported) results reported for easy access
    %   and sorting.
    %
    %   See also: BATCHRUNNER, GRAPHMETADATA.
    
    %======================== MEMBERS =================================
    properties (GetAccess = public, SetAccess = private) % Inputs
        fieldNames              % A size-M cell array of result column labels. All field names must be unique.
        fieldColumn             % A reverse map of field-name-to-column
    end
    properties
        metadata                % Problem metadata list, size=N
        data                    % Results array, size=NxM
        details                 % Additional result details, cell array, size=N
    end
    properties (Dependent)
        numRuns                 % Number of runs in the batch
        numFields               % Number of result fields per run
    end
    
    %======================== CONSTRUCTORS ============================
    methods
        function obj = BatchResult(numRuns, fieldNames)
            % Constructor for a batch of size N=numRuns with M=resultSize
            % results reported on each instance. fieldNames = size-M cell
            % array of result field names. All field names must be unique.
            obj.metadata    = cell(numRuns, 1);
            obj.data        = zeros(numRuns, numel(fieldNames));
            obj.details     = cell(numRuns, 1);
            obj.fieldNames  = fieldNames;
            
            % Compute reverse map
            obj.fieldColumn = containers.Map();
            for i = 1:numel(fieldNames)
                obj.fieldColumn(fieldNames{i}) = i;
            end
        end
    end
    
    %======================== METHODS =================================
    methods
        function data = dataColumns(obj, varargin)
            % Return data column by name.
            data = obj.data(:, obj.fieldColumns(varargin{:}));
        end
        
        function values = fieldColumns(obj, varargin)
            % Return multiple indices of columns by names.
            sz = numel(varargin);
            values = zeros(1, sz);
            for i = 1:sz
                values(i) = obj.fieldColumn(varargin{i});
            end
        end
            
        function result = subset(obj, index)
            % Return a result that contains only the runs with indices
            % INDEX. INDEX is internally sorted and duplicate indices are
            % removed.
            index = unique(index);
            result = graph.runner.BatchResult(numel(index), obj.fieldNames);
            result.metadata    = obj.metadata(index);
            result.data        = obj.data(index,:);
            result.details     = obj.details(index);
        end
            
        function appendAll(obj, other)
            % Append all results from OTHER to this result object.
            obj.metadata    = [obj.metadata; other.metadata];
            obj.data        = [obj.data; other.data];
            obj.details     = [obj.details; other.details];
        end
        
        function sortRows(obj, cols)
            %   SORTROWS(OBJ,COL) sorts the data matrix and metadata cell array based on the columns specified in the
            %     vector COL.  If an element of COL is positive, the corresponding column
            %     in DATA will be sorted in ascending order; if an element of COL is negative,
            %     the corresponding column in DATA will be sorted in descending order. For
            %     example, SORTROWS(obj,[2 -3]) sorts the rows of DATA first in ascending order
            %     for the second column, and then by descending order for the third
            %     column.
            [obj.data, index]   = sortrows(obj.data, cols);
            obj.details         = obj.details(index);
            obj.metadata        = obj.metadata(index);
        end
        
        function index = indexOfKey(obj, key)
            index = find(strcmp(cellfun(@(x)(x.key), obj.metadata, 'UniformOutput', false), key));
        end

        function remove(obj, index)
            % Append all results from OTHER to this result object.
            obj.metadata(index) = [];
            obj.data(index,:) = [];
            obj.details(index) = [];
        end
    end
    
    %======================== GET & SET ===============================
    methods
        function numRuns = get.numRuns(obj)
            % Return the number of runs in the batch.
            numRuns = numel(obj.metadata);
        end
        
        function numFields = get.numFields(obj)
            % Return the number of result fields per run.
            numFields = numel(obj.fieldNames);
        end
    end
    
    %======================== PRIVATE METHODS =========================
end
