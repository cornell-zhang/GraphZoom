classdef (Sealed) UTestRelaxWofGrid < amg.AmgFixture
    %UTestRelaxAcf Unit test that computes relaxation WOFs for
    %grid Laplacians.
    %   This class computes relaxation ACFs on grid graphs to expose their
    %   slowness as h -> 0.
    
    %=========================== PROPERTIES ==============================
    properties (Constant, GetAccess = protected)
        logger          = core.logging.Logger.getInstance('amg.runner.UTestRelaxWofGrid')
    end
    
    %=========================== CONSTRUCTORS ============================
    methods
        function obj = UTestRelaxWofGrid(name)
            %UTestRelaxWofGrid Constructor
            %   UTestRelaxWofGrid(name) constructs a test case using the
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
        function testGrid2d(obj)
            % Compute relaxation ACF for 2-D grid graphs.
            obj.runOnGridGraph(2, 2.^(2:5));
        end
        
        function testGrid3d(obj)
            % Compute relaxation ACF for 2-D grid graphs.
            obj.runOnGridGraph(3, 2.^(2:4));
        end
        
        function testGrid4d(obj)
            % Compute relaxation ACF for 2-D grid graphs.
            obj.runOnGridGraph(4, 3*2.^(0:2));
        end
    end
    
    %======================== PRIVATE METHODS ============================
    methods (Access = private)
        function runOnGridGraph(obj, dim, N)
            % Generate graphs for increasingly smaller meshsize h and run
            % relaxations on them. ACF should behave like 1 - O(h^2) as
            % h->0.
            
            batchReader = graph.reader.BatchReader;
            for n = N
                g = Graphs.grid('fd', ones(dim,1)*n);
                %eigs(g.laplacian, 5, 'sm') %TODO: move eigenvalue test to
                %a separate Generator test suite
                batchReader.add('graph', g);
            end
            
            % Compute GS relaxation WOF in a batch run
            relax           = amg.relax.RelaxFactory('relaxType', 'gs');
            runner          = RunnerRelaxAcfWof(@Problems.laplacianHomogeneous, relax);
            result          = amg.AmgFixture.BATCH_RUNNER.run(batchReader, runner);
            
            % Report results
            if (obj.logger.infoEnabled)
            amg.relax.UTestRelaxWofGrid.printResults(result);
            end
            
            %             % Assert that GS (similarly other schemes) ACF behaves like 1 -
            %             % O(h^2) (h-power should be at least 2 within 10% only, to
            %             % account for potential inaccuracies due to the maxIterations
            %             % limit).
            %             factors = logBase(exp(diff(-log(1-result.data),1)),2)
            %             hPower  = median(factors);
            %             assertTrue(min(hPower) > 1.9);
            %             % More restrictive
            %             %assertEqual(hPower, 2*ones(size(hPower)), 'relative', 0.1);
        end
    end
    
    methods (Static, Access = private)
        function printResults(result)
            % Print results to standard output (fid=1)
            printerFactory  = graph.printer.PrinterFactory;
            printer         = printerFactory.newInstance('text', result, 1);
            printer.addIndexColumn('#', 3);
            precision    = 3;
            acfWidth        = max(11, precision + 6);
            printer.addColumn('Group'   , 's', 'field'   , 'metadata.key',          'width', 28);
            printer.addColumn('#Nodes'  , 'd', 'field'   , 'metadata.numNodes',   	'width',  7);
            printer.addColumn('#Edges'  , 'd', 'field'   , 'metadata.numEdges',   	'width',  7);
            printer.addColumn('ACF'     , 's', 'function', @(x,data,z)(formatAcf(data(1), precision)), 'width',  acfWidth);
            printer.addColumn('WOF(1)'  , 'f', 'field'   , 'data(2)',             	'width',  7, 'precision', precision);
            printer.addColumn('WOF(2)'  , 'f', 'field'   , 'data(3)',             	'width',  7, 'precision', precision);
            printer.addColumn('WOF(3)'  , 'f', 'field'   , 'data(4)',             	'width',  7, 'precision', precision);
%            printer.addColumn('Min'     , 's', 'function', @(x,y,z)(formatAcf(bestIndex(x,y,z), precision)), 'width',  acfWidth);
            printer.run();
        end
        
    end
    
end
