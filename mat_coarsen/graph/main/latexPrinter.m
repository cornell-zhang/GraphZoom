function printer = latexPrinter(result, f)
%LATEXPRINTER Result bundle latex PRINTER.
%   Detailed explanation goes here

if (nargin < 2)
    f = 1;
end
PRINTER_FACTORY = graph.printer.PrinterFactory;

% Create a printer from custom run options.
printer = PRINTER_FACTORY.newInstance('latex', result, f);
%printer.addIndexColumn('#', 3);
printer.addColumn('Name'    , 's', 'field'   , 'metadata.key',      'width', 30);
printer.addColumn('Grid'    , 's', 'function', @(x,y,z)(sprintf('%d^%d', x.attributes.n(1), x.attributes.dim)), 'width',  8);
printer.addColumn('m'       , 's', 'function', @(x,y,z)(sprintf('%d', x.numEdges)), 'width',  8);
printer.addColumn('L'       , 'd', 'field'   , 'data(7)',           'width',  5);
printer.addColumn('ACF'     , 'f', 'field'   , 'data(13)',          'width',  7, 'precision', 3);
printer.addColumn('ACF-A'   , 'f', 'field'   , 'data(8)',           'width',  7, 'precision', 3);
printer.addColumn('\%Setup' , 's',  'function', @(x,y,z)(sprintf('%.f\\%%', 100*y(5)/(y(5)+10*y(6)))), 'width',  9, 'precision', 1);
printer.addColumn('\ttotal' , 's',  'function', @(x,y,z)(sprintf('%.f', (y(5)+10*y(6))*y(2)/y(3))), 'width',  9, 'precision', 1);
end
