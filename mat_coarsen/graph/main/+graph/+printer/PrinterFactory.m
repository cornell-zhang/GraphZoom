classdef (Sealed) PrinterFactory < handle
    %PRINTERFACTORY Graph batch result printer factory.
    %   New implementations batch result printers should be registered here.
    %
    %   See also: PRINTER.
    
    %======================== METHODS =================================
    methods
        function instance = newInstance(obj, printerType, batchResult, varargin) %#ok<MANU>
            % Returns a result bundle printer instance of type printerType.
            switch (printerType)
                case 'text'
                    % Plain text
                    instance = graph.printer.TextPrinter(batchResult, varargin{:});
                case 'html'
                    % HTML / Wiki syntax
                    instance = graph.printer.HtmlPrinter(batchResult, varargin{:});
                case 'latex'
                    % LaTex table syntax
                    instance = graph.printer.LatexPrinter(batchResult, varargin{:});
                otherwise
                    error('MATLAB:PrinterFactory:newInstance:InputArg', 'Unsupported printer type ''%s''', printerType);
            end
        end
    end
end
