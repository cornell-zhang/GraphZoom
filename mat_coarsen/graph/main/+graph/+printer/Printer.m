classdef Printer < graph.runner.Runnable
    %PRINTER Batch result printer.
    %   This class constructs a presentation of a BatchResult instance. It
    %   is not the responsibility of this object to open close the ouput
    %   file stream; this is an input to this class.
    %
    %   See also: BATCHRUNNER, BATCHRESULT.
    
    %=========================== PROPERTIES ==============================
    properties (GetAccess = protected, SetAccess = private) % Input
        batchResult         % Batch result to be printed.
        f                   % Output file ID
        columns             % A struct array whose elements describe the columns to be printed (title, format)
    end
    properties (GetAccess = protected, SetAccess = public) % Options
        title               % Table title
        totalWidth          % Serves as a guideline for the total table width in the relevant units (characters/pixels/...). It is not guaranteed to be the actual output width.
    end
    properties (Dependent)  % Convenient aliases
        numColumns          % size of columns
        totalColumnWidth    % Sum of all specified column widths
    end
    
    %=========================== CONSTRUCTORS ============================
    methods
        function obj = Printer(batchResult, varargin)
            %Printer Constructor.
            %   Printer(f) constructs a printer of batchResult directed to
            %   the output file ID f.
            
            obj.batchResult = batchResult;
            
            % Use standard output by default
            if (length(varargin) < 1)
                obj.f = 1;
            else
                obj.f = varargin{1};
            end
            
            obj.columns = [];
        end
    end
    
    %======================== IMPL: Runnable =============================
    methods (Sealed)
        function run(obj, dummy) %#ok
            % A template method that generates the entire output.
            obj.printBefore();
            for i = 1:obj.batchResult.numRuns
                obj.printRun(i);
            end
            obj.printAfter();
        end
    end
    
    %======================== METHODS ====================================
    methods (Sealed)
        function addIndexColumn(obj, label, varargin)
            % Add an index column (a shortcut for
            % obj.addIndexColumn('index',...)).
            
            % Default (and minimum) width determined by #runs
            minWidth = numDigits(obj.batchResult.numRuns)+2;
            if (numel(varargin) < 1)
                width = minWidth;
            else
                width = max(minWidth, varargin{1});
            end
            
            obj.addColumn(label, 'd', 'field', 'index', 'width', width);
        end
        
        function addColumn(obj, label, format, varargin)
            % OBJ.ADDCOLUMN(LABEL, FIELD, FORMAT, VARARGIN) Add a FIELD
            % data column with label LABEL. FORMAT is the printf format
            % part ('s', 'd', 'e', 'f' or 'g').
            %
            % The field TYPE (=part of the FIELD string before the first
            % '.' occurrence) determines how column data is retrieved:
            %
            %   TYPE='index': an index column. Prints I for run number I.
            %
            %   TYPE='metadata': FIELD is interpreted to be a property of
            %   OBJ.BATCHRESULT.METADATA{I}.
            %
            %   TYPE='data': FIELD is interpreted to be an element of the
            %   arrayOBJ.BATCHRESULT.DATA{I}.
            %
            %   FUNCTION: if present, it is used as a data transformation
            %   functor. Must be a function handle that takes the arguments
            %   METADATA, DATA, DETAILS.
            %
            % VARARGIN contains optional arguments:
            %
            %   'width' - field width 'precision' - precision for formats
            %   'f','e'
            
            column = graph.printer.Printer.parseAddColumnArgs(label, format, varargin{:});
            
            % Post-processing
            if (~isempty(column.field))
                [column.substruct, column.type] = ...
                    graph.printer.Printer.getColumnFieldSubstruct(column.field);
            elseif (~isempty(column.function))
                column.type = 'function';
            end
            column              = obj.postProcessColumn(column);
            
            % Add column to column list
            obj.columns         = [obj.columns; {column}];
        end
    end
    
    %======================== GET & SET ==================================
    methods
        function numColumns = get.numColumns(obj)
            % Return the number of columns to print.
            numColumns = numel(obj.columns);
        end
        
        function totalColumnWidth = get.totalColumnWidth(obj)
            % Return the sum of all specified column widths.
            totalColumnWidth = 0;
            for i = 1:obj.numColumns
                column = obj.columns{i};
                totalColumnWidth = totalColumnWidth + column.width;
            end
        end
    end
    
    %======================== PRIVATE METHODS ============================
    methods (Abstract, Access = protected)
        result = printBefore(obj)
        % Print a header for the result.
        
        result = printAfter(obj)
        % Print a footer for the result.
        
        result = printRun(obj, i)
        % Print a row with statistics of run #i in the batch.
        
        column = postProcessColumn(obj, column)
        % Build the format string and other useful cached fields for a
        % COLUMN object and store them in that object.
    end
    
    methods (Sealed, Access = protected)
        function result = getColumnData(obj, i, column)
            % Return column data. Works for arbitrarily-nested sub-fields
            % of metadata or data using a dot notation. with a ".".
            metadata = obj.batchResult.metadata{i};
            data     = obj.batchResult.data(i,:);
            details  = obj.batchResult.details{i};
            switch (column.type)
                case 'index'
                    result = i;
                case 'metadata'
                    result = subsref(metadata, column.substruct);
                case 'data'
                    result = data(column.substruct);
                case 'function',
                    % Apply functor to the current data row
                    result = column.function(metadata, data, details);
                otherwise
                    error('MATLAB:PrinterFactory:getColumnData:InputArg', 'Unsupported column type ''%s''', column.type);
            end
        end
        
        function print(obj, formatString, varargin)
            % Print to the output file if it is valid.
            if (obj.f > 0)
                fprintf(obj.f, formatString, varargin{:});
            end
        end
    end
    
    methods (Static, Access = private)
        function args = parseAddColumnArgs(label, format, varargin)
            % Parse input arguments for the addColumn() method.
            p                   = inputParser;
            p.FunctionName      = 'Printer';
            p.KeepUnmatched     = true;
            p.StructExpand      = true;
            
            p.addRequired  ('label', @ischar);
            p.addRequired  ('format', @(x)(any(strcmp(x,{'s', 'd', 'e' ,'f', 'g'}))));
            p.addParamValue('field', [], @ischar);
            p.addParamValue('width', [], @isnumeric);
            p.addParamValue('precision', [], @isNonnegativeIntegral);
            p.addParamValue('function', [], @(x)(isa(x, 'function_handle')));
            
            p.parse(label, format, varargin{:});
            args = p.Results;
        end
        
        function [s, type] = getColumnFieldSubstruct(field)
            % Convert a raw column field string FIELD nto a nested field
            % substruct S. Removes the metadata/data prefix. S is cached in
            % the column for dynamic field access by printRun(). Also
            % returns the field type (=parent object, index/metadata/data).
            if (isempty(field))
                % A non-field type, e.g. a function type
                s = [];
                type = [];
            elseif (strncmp(field, 'index', length('index')))
                s = [];
                type = 'index';
            elseif (strncmp(field, 'data', length('data')))
                 % field is an index into the data array, strip the
                 % 'data.()' string parts
                field_cell = strread(field, '%s', 'delimiter', '()');
                s = str2double(field_cell{2});
                type = 'data';
            else
                % Nested metadata field, prepare subsref substruct
                field_cell = strread(field, '%s', 'delimiter', '.');
                type = field_cell{1};
                if (any(strcmp(type, {'metadata', 'data'})))
                    field_cell = field_cell(2:end);
                else
                    error('MATLAB:Printer:getColumnFieldSubstruct', 'Invalid field ''%s''', field);
                end
                s = struct('type', '.', 'subs', field_cell);
            end
        end
    end
end