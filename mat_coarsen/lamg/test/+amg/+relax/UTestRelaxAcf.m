classdef (Sealed) UTestRelaxAcf < amg.AmgFixture
    %UTestRelaxAcf Unit test that computes stand-alone relaxation ACFs.
    %   This class computes relaxation ACFs on various graph instances to
    %   expose their slowness in many cases.
    
    %=========================== PROPERTIES ==============================
    properties (Constant, GetAccess = protected)
        logger          = core.logging.Logger.getInstance('amg.relax.UTestRelaxAcf')
    end
    
    %=========================== CONSTRUCTORS ============================
    methods
        function obj = UTestRelaxAcf(name)
            %UTestRelaxAcf Constructor
            %   UTestRelaxAcf(name) constructs a test case using the
            %   specified name.
            obj = obj@amg.AmgFixture(name);
        end
    end
    
    %=========================== SETUP METHODS ===========================
    methods
        function setUp(obj)
            setUp@amg.AmgFixture(obj);
            
            if (obj.logger.infoEnabled)
                obj.logger.info('\n');
            end
        end
    end
    
    %=========================== TESTING METHODS =========================
    methods
        function testRelaxAcf(obj)
            % Test loading graphs and computing the GS and Jacobi ACFs.
            global GLOBAL_VARS;
            
            % Load graphs
            batchReader = graph.reader.BatchReader;
            batchReader.add('dir', [GLOBAL_VARS.data_dir '/mat/walshaw']);
            selectedGraphs = graph.api.GraphUtil.getGraphsWithEdgesBetween(...
                batchReader, 0, AmgTestUtil.MAX_EDGES);
            %selectedGraphs = selectedGraphs(47);

            % Consider only singly-connected graphs
            res = amg.AmgFixture.BATCH_RUNNER.run(batchReader, RunnerConnComp,selectedGraphs);
            selectedGraphs(res.data(:,res.fieldColumn('numComponents')) > 1) = [];
            
            % Run methods on graphs
            [methodLabels, methodInstances] = amg.relax.UTestRelaxAcf.getRelaxSchemes();
            result = AmgTestUtil.compareMethods(batchReader, selectedGraphs, ...
                methodLabels, methodInstances);
            % Sort results by descending best ACF
            result.sortRows(-result.fieldColumn('best'));
            
            % Report results
            if (obj.logger.infoEnabled)
                amg.relax.UTestRelaxAcf.printResults(methodLabels, result);
            end
            %assertEqual(batchReader.size, numel(smallGraphs));
        end
    end
    
    %=========================== PRIVATE METHODS==========================
    methods (Static, Access = private)
        function printResults(methodLabels, result)
            % Print results to standard output (fid=1)
            printerFactory  = graph.printer.PrinterFactory;
            printer         = printerFactory.newInstance('text', result, 1);
            printer.addIndexColumn('#', 3);
            printer.addColumn('Group'   , 's', 'field'   , 'metadata.key',          'width', 30);
            printer.addColumn('#Nodes'  , 'd', 'field'   , 'metadata.numNodes',   	'width',  8);
            printer.addColumn('#Edges'  , 'd', 'field'   , 'metadata.numEdges',   	'width',  9);
            printer.addColumn('J'       , 'f', 'field'   , 'data(1)',             	'width',  7, 'precision', 2);
            printer.addColumn('GS'      , 'f', 'field'   , 'data(2)',             	'width',  7, 'precision', 2);
            printer.addColumn('SOR'     , 'f', 'field'   , 'data(3)',             	'width',  7, 'precision', 2);
            printer.addColumn('Best'    , 'f', 'field'   , 'data(4)',             	'width',  7, 'precision', 2);
            printer.addColumn('Method'  , 's', 'function', @(x,y,z)(methodLabels{AmgTestUtil.bestAcfIndex(x,y,z)}), 'width',  7);
            printer.run();
        end
        
        function [methodLabels, methodInstances] = getRelaxSchemes()
            % Relaxation schemes of interest
            import amg.api.Options
            relaxJacobi     = amg.relax.RelaxFactory('relaxType', 'jacobi');
            relaxGs         = amg.relax.RelaxFactory('relaxType', 'gs');
            relaxSor        = amg.relax.RelaxFactory('relaxType', 'gs', 'omega', 1.5);
            methodLabels    = {'J', 'GS', 'SOR-1.5'};
            methodInstances = {relaxJacobi, relaxGs, relaxSor};
        end
    end
end
