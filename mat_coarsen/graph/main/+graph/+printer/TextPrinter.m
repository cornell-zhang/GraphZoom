classdef (Sealed) TextPrinter < graph.printer.Printer
    %TEXTPRINTER Prints a text table of a graph batch run.
    %   This class prints a batch run results in a table.
    %
    %   See also: PRINTER.
    
    %=========================== PROPERTIES ==============================
    
    %=========================== CONSTRUCTORS ============================
    methods
        function obj = TextPrinter(batchResult, varargin)
            %TextPrinter Constructor.
            obj = obj@graph.printer.Printer(batchResult, varargin{:});
            
            % Set default options
        end
    end
    
    %======================== IMPL: PRINTER ==============================
    methods (Access = protected)
        function printBefore(obj)
            % Print table header.
            
            % Line 1
            obj.print('Number of graphs: %d\n\n', obj.batchResult.numRuns);
            for col = 1:obj.numColumns
                column = obj.columns{col};
                obj.print(column.labelFormat, column.label);
            end
            obj.print('\n');
            
            % Line 2
            obj.print('%s\n', repmat('-', 1, obj.totalColumnWidth));
        end
        
        function printAfter(obj, dummy) %#ok %#ok<MANU>
            % Print table footer.
        end
        
        function printRun(obj, i)
            % Print a table row with graph #i statistics.
            for col = 1:obj.numColumns
                column = obj.columns{col};
                obj.print(column.dataFormat, obj.getColumnData(i, column));
            end
            obj.print('\n');
        end
        
        function column = postProcessColumn(obj, column) %#ok<MANU>
            % Build the format string and other useful cached fields for a COLUMN object 
            % and store them in that object.
            
            % fprintf format string
            s = '%-';
            if (~isempty(column.width))
                s = [s sprintf('%d', column.width)];
            end
            if (any(strcmp(column.format, {'e', 'f', 'g'})) && ~isempty(column.precision))
                s = [s sprintf('.%d', column.precision)];
            end
            s = [s sprintf('%s', column.format)];
            column.dataFormat = s;
            
            % fprintf format string of the column's label
            s = '%-';
            if (~isempty(column.width))
                s = [s sprintf('%d', column.width)];
            end
            s = [s 's']; % Label is always a string
            column.labelFormat = s;
        end
    end
end

