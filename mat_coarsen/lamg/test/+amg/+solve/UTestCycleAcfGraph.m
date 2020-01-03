classdef (Sealed) UTestCycleAcfGraph < amg.AmgFixture
    %UTestCycleAcfGraph Unit test that computes stand-alone relaxation
    %ACFs.
    %   This class computes relaxation ACFs on various graph instances to
    %   expose their slowness in many cases.
    
    %=========================== PROPERTIES ==============================
    properties (Constant, GetAccess = protected)
        logger          = core.logging.Logger.getInstance('amg.solve.UTestCycleAcfGraph')
    end
    
    %=========================== CONSTRUCTORS ============================
    methods
        function obj = UTestCycleAcfGraph(name)
            %UTestCycleAcfGraph Constructor
            %   UTestCycleAcfGraph(name) constructs a test case using the
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
        function testCycleAcf(obj) %#ok<MANU>
            % Test loading graphs and computing HCR and cycle ACFs for many graph instances.
            global GLOBAL_VARS;
            
            % Load graphs
            batchReader = graph.reader.BatchReader;
            batchReader.add('dir', [GLOBAL_VARS.data_dir '/walshaw']);
            selectedGraphs = graph.api.GraphUtil.getGraphsWithEdgesBetween(...
                batchReader, 0, 7);
            %selectedGraphs = selectedGraphs(39);
            %selectedGraphs = selectedGraphs(3);

            % Set multilevel options
            mlOptions = amg.solve.UTestCycleAcfGraph.defaultOptions();
            mlOptions.eliminationMaxDegree = 5;
            % Fix random seed
%             if (~isempty(mlOptions.randomSeed))
%                 setRandomSeed(mlOptions.randomSeed);
%             end
            
            % Run multigrid on graphs in batch mode
            solver = Solvers.newSolver('lamg', mlOptions, ...
                'steadyStateTol', 1e-2, 'output', 'full');
            runner = lin.runner.RunnerSolver(@Problems.laplacianHomogeneous, 'lamg', solver);
            runner.solverContext = lin.runner.SolverContext;
            result = amg.AmgFixture.BATCH_RUNNER.run(batchReader, ...
                runner, selectedGraphs); %#ok

            % Sort results by descending worst ACF
            %result.sortRows(-result.fieldColumn('beta'));
            % Report results - TODO: move to a separate test* program
            %resultFile = strcat(GLOBAL_VARS.out_dir, '/graph/cycle_results.mat');
            %create_dir(resultFile, 'file');
            %save(resultFile, 'result');
%             if (obj.logger.infoEnabled)
%                 amg.solve.UTestCycleAcfGraph.printResults(result);
%             end
            %assertEqual(batchReader.size, numel(smallGraphs));
        end
        
        function testErdos972(obj)
            % A graph that originally yielded ACF = 40,000 (!), but has a
            % simple structure (500x500 dense block + 4200 nodes, each of
            % which depends on few dense block nodes only).
            [dummy, details] = obj.graphAcf('lap/uf/Pajek/Erdos972/component-1', 'logLevel', 2); %#ok
            assertTrue(details.acf < 0.12, 'Erdos972 with elimination levels should have a small ACF');
        end
        
        function testOneLevelMethod(obj)
            % Test a graph for which relaxation converges sufficiently quickly.
            [dummy, details] = obj.graphAcf('lap/walshaw/coloring/myciel2', 'maxDirectSolverSize', 4, 'setupNumLevels', 1); %#ok
            assertTrue(details.acf < 0.25, 'myciel2 ACF not small enough even though it should be');        	
            assertEqual(details.work, 1, 'One-level method should have W=1');
        end
        
        function testDirectSolver(obj)
            % Test a graph for which a direct solver is used.
            [dummy, details] = obj.graphAcf('lap/walshaw/coloring/myciel2'); %#ok
            assertEqual(details.acf, 0, 'Direct solver ACF should be 0');
            assertEqual(details.work, 0, 'Direct solver should have W=0');
        end
        
        % Affinity, Recompute strategies now deprecated
        function inactiveTestSmallGraphAffinityRecompute(obj)
            % A small graph  in which we recompute affinities at each s
            % instead of updating affinities -- potential optimization.
            data1 = obj.graphAcf('lap/walshaw/coloring/miles750', 'aggregationUpdate', 'affinity');
            data2 = obj.graphAcf('lap/walshaw/coloring/miles750', 'aggregationUpdate', 'recompute');
            assertElementsAlmostEqual(data1(1), data2(1), 'relative', 1e-8); %'Did not obtain identical results with equivalent aggregation update strategies');
        end
    end
    
    %=========================== PRIVATE METHODS==========================
    methods (Access = private)
        function [data, details] = graphAcf(obj, key, varargin) %#ok<MANU>
            % Compute ML cycle ACF for a graph problem whose key is KEY.
            
            % Set multilevel options
            defaultOptions = amg.solve.UTestCycleAcfGraph.defaultOptions();
            defaultOptions.eliminationMaxDegree = 3;
            mlOptions = amg.api.Options.fromStruct(defaultOptions, varargin{:});
            
            % Fix random seed
%             if (~isempty(mlOptions.randomSeed))
%                 setRandomSeed(mlOptions.randomSeed);
%             end
            
            % Run ML setup
            g = Graphs.testInstance(key);
            solver = Solvers.newSolver('lamg', mlOptions, ...
                'steadyStateTol', 1e-2, 'output', 'full');
            runner = lin.runner.RunnerSolver(@Problems.laplacianHomogeneous, 'lamg', solver);
            runner.solverContext = lin.runner.SolverContext;
            [data, details] = runner.run(g);
        end
    end
    
    methods (Static, Access = private)
        function mlOptions = defaultOptions()
            % Standard Multi-level options for a two-level experiment.
            % Default multilevel mlOptions.
            mlOptions                           = amg.api.Options;
            
            % Debugging flags
            mlOptions.logLevel                  = 1;
            % mlOptions.plotCoarsening            = true;
            mlOptions.plotLevels               = false;
            %mlOptions.randomSeed                = 14;
            
            % Multi-level cycle
            mlOptions.cycleDirectSolver         = true;
            mlOptions.numCycles                 = 20;
            %mlOptions.errorNorm                 = @errorNormResidual;
            mlOptions.combinedIterates          = 1;
            mlOptions.setupNumAggLevels        = 100;
            mlOptions.cycleIndex                = 1.2;
            mlOptions.nuDesign                  = 'split_evenly';
            
            % Test vectors
            mlOptions.tvNum                     = 10;
            mlOptions.tvSweeps                  = 5;
            
            % Aggregation
            mlOptions.aggregationType           = 'limited';
            mlOptions.aggregationUpdate         = 'affinity-energy-mex';
            mlOptions.minCoarseningRatio        = 0.3;
            mlOptions.maxHcrAcf                 = 0.4;
            mlOptions.minCoarseSize             = 10;
            mlOptions.nuOptimization            = false;
            
            % Energy correction
            mlOptions.energyCorrectionType      = 'flat';
            mlOptions.rhsCorrectionFactor       = 4/3;
        end
        
        function printResults(result)
            % Print results to standard output (fid=1)
            printerFactory  = graph.printer.PrinterFactory;
            printer         = printerFactory.newInstance('html', result, 1);
            printer.addIndexColumn('#', 3);
            printer.addColumn('Group'   , 's', 'field'   , 'metadata.key',      'width', 30);
            printer.addColumn('#Nodes'  , 'd', 'field'   , 'metadata.numNodes', 'width',  8);
            printer.addColumn('#Edges'  , 'd', 'field'   , 'metadata.numEdges', 'width',  9);
            printer.addColumn('HCR'     , 'f', 'field'   , 'data(6)',           'width',  7, 'precision', 3);
            printer.addColumn('ACF'     , 'f', 'field'   , 'data(1)',           'width',  7, 'precision', 3);
            printer.addColumn('Work'    , 'f', 'field'   , 'data(4)',           'width',  8, 'precision', 2);
            printer.addColumn('#levels' , 'd', 'field'   , 'data(5)',           'width',  5);
            printer.addColumn('beta'    , 'f', 'field'   , 'data(7)',           'width',  7, 'precision', 3);
            printer.addColumn('Components', 'd', 'field'   , 'data(8)',           'width',  5);
            printer.run();
        end        
    end
end
