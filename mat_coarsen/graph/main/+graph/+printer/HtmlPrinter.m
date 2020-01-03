classdef (Sealed) HtmlPrinter < graph.printer.Printer
    %HTMLPRINTER Prints an HTML table of a graph batch run.
    %   This class prints a batch run results in an HTML table. Suitable
    %   for inclusion in a BAMG Wiki page.
    %
    %   See also: PRINTER.
    
    %=========================== PROPERTIES ==============================
    
    %=========================== CONSTRUCTORS ============================
    methods
        function obj = HtmlPrinter(batchResult, varargin)
            %TextPrinter Constructor.
            obj = obj@graph.printer.Printer(batchResult, varargin{:});
            
            % Set default options
            obj.totalWidth      = 700;
        end
    end
    
    %======================== IMPL: PRINTER ===========================
    methods (Access = protected)
        function printBefore(obj)
            % Print table header.

            % Table caption
            obj.print('%s\n', ...
                graph.printer.HtmlPrinter.wrapInTag('p', ...
                graph.printer.HtmlPrinter.wrapInTag('strong', ...
                sprintf('Table: %s', obj.title))));
            obj.print('%s\n', graph.printer.HtmlPrinter.openTag('table', ...
                'border', '1', 'width', sprintf('%d', obj.totalWidth)));
            % Wiki doesn't support thead
            obj.print('%s\n', graph.printer.HtmlPrinter.openTag('tbody'));

            % Header line
            obj.print('%s\n', graph.printer.HtmlPrinter.openTag('tr'));
            for col = 1:obj.numColumns
                column = obj.columns{col};
                obj.printHeaderCell(column.label);
            end
            obj.print('%s\n', graph.printer.HtmlPrinter.closeTag('tr'));
        end
        
        function printAfter(obj, dummy) %#ok
            % Print table footer.
            
            % Table end
            obj.print('%s\n', graph.printer.HtmlPrinter.closeTag('tbody'));
            obj.print('%s\n', graph.printer.HtmlPrinter.closeTag('table'));
        end
        
        function printRun(obj, i)
            % Print a table row with graph #i statistics.
            obj.print('%s\n', graph.printer.HtmlPrinter.openTag('tr'));
            for col = 1:obj.numColumns
                column = obj.columns{col};
                obj.print('  %s\n', graph.printer.HtmlPrinter.wrapInTag('td', ...
                    sprintf(column.dataFormat, obj.getColumnData(i, column))));
            end
            obj.print('%s\n', graph.printer.HtmlPrinter.closeTag('tr'));
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
        function printHeaderCell(obj, body)
            % Print an HTML table header cell to the output stream.
            obj.print('  %s\n', graph.printer.HtmlPrinter.wrapInTag('td', ...
                graph.printer.HtmlPrinter.wrapInTag('strong', body)));
        end
    end
    
    methods (Static, Access = private)
        function s = openTag(name, varargin)
            % Print an XML element start.
            s = sprintf('<%s', name);
            if (~isempty(varargin))
                attributes = struct(varargin{:});
                attributeNames = fieldnames(attributes);
                for i = 1:numel(attributeNames)
                    attributeName = attributeNames{i};
                    s = [s, ' ', sprintf('%s="%s"', attributeName, attributes.(attributeName))]; %#ok
                end
            end
            s = [s, '>'];
        end
        
        function s = closeTag(name)
            % Print an XML element end.
            s = sprintf('</%s>', name);
        end
        
        function s = wrapInTag(name, body, varargin)
            % Print BODY wrapped in the HTML tag NAME.
            s = sprintf('%s%s</%s>', ...
                graph.printer.HtmlPrinter.openTag(name, varargin{:}), body, name);
        end        
    end
end
