classdef (Sealed) LatexPrinter < graph.printer.Printer
    %LATEXPRINTER Prints a LaTeX table of a graph batch run.
    %   This class prints a batch run results in LaTeX table format..
    %
    %   See also: PRINTER.
    
    %=========================== PROPERTIES ==============================
    
    %=========================== CONSTRUCTORS ============================
    methods
        function obj = LatexPrinter(batchResult, varargin)
            %TextPrinter Constructor.
            obj = obj@graph.printer.Printer(batchResult, varargin{:});
        end
    end
    
    %======================== IMPL: PRINTER ===========================
    methods (Access = protected)
        function printBefore(obj)
            % Print table header.

            % Table caption
            obj.print('\\begin{table}[htbp]\n');
            obj.print('\\centering\\footnotesize\n');

            % Column line
            obj.print('\\begin{tabular}{');
            for col = 1:obj.numColumns
                obj.print('|c');
            end
            obj.print('|');
            obj.print('}\n');
            
            % Header line
            obj.hline();
            for col = 1:obj.numColumns
                column = obj.columns{col};
                s = strrep(column.label, '#', '\#');
                obj.print('$%s$', s);
                
                if (col < obj.numColumns)
                    obj.print('&');
                end
            end
            obj.endOfLine();
            obj.hline();
        end
        
        function printAfter(obj, dummy) %#ok
            % Print table footer.
            
            obj.print('\\end{tabular}\n');
            obj.print('\\caption{My caption.}\n');
            obj.print('\\label{My label}\n');
            obj.print('\\end{table}\n');
        end
        
        function printRun(obj, i)
            % Print a table row with graph #i statistics.
            for col = 1:obj.numColumns
                column = obj.columns{col};
                obj.print('%s', obj.printCell(i, column));
                if (col < obj.numColumns)
                    obj.print('&');
                end
            end
            obj.endOfLine();
        end
        
        function column = postProcessColumn(obj, column) %#ok<MANU>
            % Build the format string and other useful cached fields for a COLUMN object 
            % and store them in that object.
            
            % fprintf format string
            s = '%';
            if (any(strcmp(column.format, {'e', 'f', 'g'})) && ~isempty(column.precision))
                s = [s sprintf('.%d', column.precision)];
            end
            s = [s sprintf('%s', column.format)];
            column.dataFormat = s;
        end
    end
    
    %======================== PRIVATE METHODS =========================
    methods (Access = private)
        function s = printCell(obj, row, column)
            % Format a table cell into a string.
            data = obj.getColumnData(row, column);
            switch (column.format)
                case 'e'
                    s = formatLatex(data, column.precision);
                otherwise
                    s = sprintf(column.dataFormat, data);
            end
            s = ['$' s '$'];
        end
        
        function hline(obj)
            % Print an HTML table header cell to the output stream.
            obj.print('\\hline\n');
        end
        
        function endOfLine(obj)
            % Print an HTML table header cell to the output stream.
            obj.print('\\\\ \\hline\n');
        end
        
        function wrapText(obj, body)
            % Print an HTML table header cell to the output stream.
            obj.print('  %s\n', graph.printer.HtmlPrinter.wrapInTag('td', ...
                graph.printer.HtmlPrinter.wrapInTag('strong', body)));
        end
    end
    
    methods (Static, Access = private)
    end
end
