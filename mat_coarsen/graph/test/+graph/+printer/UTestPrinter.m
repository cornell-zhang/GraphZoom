classdef (Sealed) UTestPrinter < graph.GraphFixture
    %UTestPrinter Unit test of graph experiment result printer.
    %   This class includes unit tests of different Printers.
    
    %=========================== PROPERTIES ==============================
    properties (Constant, GetAccess = private)
        logger          = core.logging.Logger.getInstance('graph.printer.UTestPrinter')
        MIN_EDGES       = 0                  % Minimum # edges in graphs of interest
        MAX_EDGES       = 3000 % 1e+6        % Maximum # edges in graphs of interest
    end
    
    %=========================== CONSTRUCTORS ============================
    methods
        function obj = UTestPrinter(name)
            %UTestBatchRunner Constructor
            %   UTestBatchRunner(name) constructs a test case using the
            %   specified name.
            obj = obj@graph.GraphFixture(name);
        end
    end
    
    %=========================== TESTING METHODS =========================
    methods
        function testTextPrinter(obj)
            % Print graph statistics in a text table.
            
            % Get results
            result = obj.graphStats(graph.printer.UTestPrinter.MIN_EDGES, graph.printer.UTestPrinter.MAX_EDGES);
            
            % Sort results
            result.sortRows(-result.fieldColumn('numEdges'));
            
            % Print results
            printerFactory  = graph.printer.PrinterFactory;          
            printer         = printerFactory.newInstance('text', result, -1);
            printer.addIndexColumn('#', 3);
            printer.addColumn('Group'   , 's', 'field'   , 'metadata.group',           'width', 20);
            printer.addColumn('Name'    , 's', 'field'   , 'metadata.name',       	   'width', 17);
%            printer.addColumn('#Nodes'  , 'd', 'field'   , 'metadata.numNodes',   	   'width',  8);
            printer.addColumn('#Edges'  , 'd', 'field'   , 'data(1)',             	   'width',  9);
            printer.addColumn('Size'    , 's', 'function', @graph.printer.sizeString,  'width',  7);
            printer.addColumn('Size'    , 's', 'function', @graph.printer.elapsedTime, 'width', 18);
            printer.run();
        end
        
        function testHtmlPrinter(obj)
            % Print graph statistics in an HTML text table.
            result = obj.graphStats(graph.printer.UTestPrinter.MIN_EDGES, graph.printer.UTestPrinter.MAX_EDGES);
            printerFactory  = graph.printer.PrinterFactory;
            printer         = printerFactory.newInstance('html', result, -1);
            printer.totalWidth = 800;
            printer.title   = sprintf('Descriptive Statistics, #instances = %d', result.numRuns);
            printer.addIndexColumn('#');
            printer.addColumn('Group'   , 's', 'field'   , 'metadata.group'         );
            printer.addColumn('Name'    , 's', 'field'   , 'metadata.name'          );
            printer.addColumn('#Nodes'  , 'd', 'field'   , 'metadata.numNodes'      );
            printer.addColumn('#Edges'  , 'd', 'field'   , 'data(1)'                );
            printer.addColumn('#Edges'  , 's', 'field'   , 'metadata.description'   );
            printer.run();
        end
   
    end
    
    %=========================== PRIVATE METHODS =========================
    methods (Access = private)
    end
    
end
