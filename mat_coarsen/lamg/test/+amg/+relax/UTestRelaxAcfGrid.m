classdef (Sealed) UTestRelaxAcfGrid < amg.AmgFixture
    %UTestRelaxAcf Unit test that computes stand-alone relaxation ACFs for
    %grid Laplacians.
    %   This class computes relaxation ACFs on grid graphs to expose their
    %   slowness as h -> 0.
    
    %=========================== PROPERTIES ==============================
    properties (Constant, GetAccess = protected)
        logger          = core.logging.Logger.getInstance('amg.relax.UTestRelaxAcfGrid')
    end
    
    %=========================== CONSTRUCTORS ============================
    methods
        function obj = UTestRelaxAcfGrid(name)
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
        function testGrid2d(obj)
            % Compute relaxation ACF for 2-D grid graphs.
            obj.runOnGridGraph(2,  2.^(3:6), 1.4);
        end
        
        function testGrid3d(obj)
            % Compute relaxation ACF for 2-D grid graphs.
            obj.runOnGridGraph(3,  3*2.^(0:2), 1.4);
        end
    end
    
    %======================== PRIVATE METHODS ============================
    methods (Access = private)
        function runOnGridGraph(obj, dim, N, tol)
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
            
            % Run methods on graphs; use a custom ACF computer for a more
            % precise ACF estimation
            resultComputer = lin.api.AcfComputer(...
                'maxIterations', 1000, ...
                'steadyStateTol', 1e-5, ...
                'acfStallValue', 0.99999, ...
                'errorNorm', @errorNormL2);
            [methodLabels, methodInstances] = amg.relax.UTestRelaxAcfGrid.getRelaxSchemes();
            result = AmgTestUtil.compareMethods(batchReader, [], methodLabels, methodInstances, ...
                resultComputer);
            
            % Report results
            if (obj.logger.infoEnabled)
                amg.relax.UTestRelaxAcfGrid.printResults(methodLabels, result);
            end
            % Assert that GS (similarly other schemes) ACF behaves like 1 -
            % O(h^2) (h-power should be at least 2 within 10% only, to
            % account for potential inaccuracies due to the maxIterations
            % limit).
            factors = logBase(exp(diff(-log(1-result.data),1)),2);
            if (obj.logger.infoEnabled)
                disp(factors);
            end
            hPower  = median(factors);
            assertTrue(min(hPower) > tol); % Should ideally be 2
            % More restrictive
            %assertEqual(hPower, 2*ones(size(hPower)), 'relative', 0.1);
        end
    end
    
    methods (Static, Access = private)
        function printResults(dummy, result) %#ok
            % Print results to standard output (fid=1)
            printerFactory  = graph.printer.PrinterFactory;
            printer         = printerFactory.newInstance('text', result, 1);
            printer.addIndexColumn('#', 3);
            printer.addColumn('h'       , 'e', 'function', @(x,y,z)(x.attributes.h(1)), 'width',  12, 'precision', 3);
            printer.addColumn('#Nodes'  , 'd', 'field'   , 'metadata.numNodes',   	'width',  8);
            printer.addColumn('#Edges'  , 'd', 'field'   , 'metadata.numEdges',   	'width',  9);
            printer.addColumn('J'       , 'f', 'field'   , 'data(1)',             	'width',  7, 'precision', 4);
            printer.addColumn('GS'      , 'f', 'field'   , 'data(2)',             	'width',  7, 'precision', 4);
            printer.addColumn('SOR'     , 'f', 'field'   , 'data(3)',             	'width',  7, 'precision', 4);
            printer.run();
        end
        
        function [methodLabels, methodInstances] = getRelaxSchemes()
            % Relaxation schemes of interest
            relaxJacobi     = amg.relax.RelaxFactory('relaxType', 'jacobi', 'relaxOmega', 0.5);
            relaxGs         = amg.relax.RelaxFactory('relaxType', 'gs');
            relaxSor        = amg.relax.RelaxFactory('relaxType', 'gs', 'relaxOmega', 1.5);
            methodLabels    = {'0.5-J', 'GS', 'SOR-1.5'};
            methodInstances = {relaxJacobi, relaxGs, relaxSor};
        end
    end
    
end
