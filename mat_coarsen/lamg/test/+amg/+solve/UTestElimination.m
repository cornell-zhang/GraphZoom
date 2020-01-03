classdef (Sealed) UTestElimination < amg.AmgFixture
    %UTestElimination Unit test of low-impact node elimintation.
    %   This class executes tests of a low-degree (0-, 1- and 2-) node
    %   elimination.
    
    %=========================== PROPERTIES ==============================
    properties (Constant, GetAccess = protected)
        logger          = core.logging.Logger.getInstance('amg.solve.UTestLowImpact')
    end
    properties (GetAccess = private, SetAccess = private)
        acfComputer     % Computes ACF
    end
    
    %=========================== CONSTRUCTORS ============================
    methods
        function obj = UTestElimination(name)
            %UTestElimination Constructor
            %   UTestElimination(name) constructs a test case using the
            %   specified name.
            obj = obj@amg.AmgFixture(name);
        end
    end
    
    %=========================== SETUP METHODS ===========================
    methods
        function setUp(obj)
            setUp@amg.AmgFixture(obj);
            
            obj.acfComputer = lin.api.AcfComputer('maxIterations', 30, ...
                'output', 'full', 'steadyStateTol', 1e-2, 'sampleSize', 2, ...
                'removeZeroModes', 'none', ...
                'errorNorm', @errorNormResidual);
        end
    end
    
    %=========================== TESTING METHODS =========================
    methods
        function testDisconnectedNodes(obj)
            % Test eliminating zero-degree nodes.
            
            % Load graph that is known to cause 0 rows & cols at some
            % coarser level
            problem = AmgTestUtil.loadProblem('lap/walshaw/coloring/huck/component-1');
            
            % Set up multigrid cycle
            mlOptions   = amg.solve.UTestElimination.defaultOptions();
            mlOptions.logLevel       = 2;
            mlOptions.setupNumLevels = 2;
            mlOptions.maxDirectSolverSize = 53;
            %mlOptions.setupNumAggLevels = 2;
            mlSetup     = amg.setup.MultilevelSetup(mlOptions);
            setup       = mlSetup.build(problem);
            if (obj.logger.debugEnabled)
                disp(setup);
            end
            cycle = amg.solve.SolverLamgLaplacian.solveCycle(setup, problem.b, mlOptions);
            acf   = obj.acfComputer.run(problem, cycle);
            assertTrue(abs(acf) < 1e-12, 'Exact elimination should have 0 ACF');
        end
        
        function testDisconnectedNodesNonHom(obj)
            % Test eliminating zero-degree nodes with a non-homogeous RHS.
            
            % Load graph that is known to cause 0 rows & cols at some
            % coarser level
            acf = obj.eliminationNonHom('lap/walshaw/coloring/huck/component-1', 2);
            assertTrue(abs(acf) < 1e-12, 'Exact elimination should have 0 ACF');
        end
        
        function inactiveTestDisconnectedNodesNonHomMixedLevels(obj)
            % Test eliminating zero-degree nodes with a non-homogeous RHS.
            % Both elim, bamg levels are used here
            %
            % Test refers to an old graph that no longer exists. New graph
            % does not require elimination.
            
            % Load graph that is known to have multiple components (2) and
            % involves both elim, bamg levels in its setup
            acf = obj.eliminationNonHom('lap/uf/HB/nos1/component-1', 7);
            assertTrue(acf < 0.4, 'Exact elimination should have a small ACF');
        end
        
        function testGrid1dNodes(obj) %#ok<MANU>
            % Test finding low-imact nodes in a 1-D graph.
            
            % Create a graph problem
            n = 20;
            problem = AmgTestUtil.newGridProblem(n, 'normalized', true);
            [f, c] = lowDegreeNodes(problem.g.adjacency, [], 3);
            assertEqual(f, (1:2:n)');
            assertEqual(c, (2:2:n)');
        end
        
        function testGrid1d(obj)
            % Test eliminating nodes from a 1-D graph. Two-level method (or
            % any cycle with elimination levels only) should not be a
            % direct solver, but have a small ACF.
            
            % Perform only 1 cycle to compute ACF
            obj.acfComputer = lin.api.AcfComputer('maxIterations', 1, ...
                'output', 'full', 'steadyStateTol', 1e-2, 'sampleSize', 2, ...
                'removeZeroModes', 'none', ...
                'errorNorm', @errorNormL2);
            
            % Create a graph problem
            problem     = AmgTestUtil.newGridProblem(40, 'normalized', true);
            
            % Set up multigrid cycle
            mlOptions   = amg.solve.UTestElimination.defaultOptions();
            mlOptions.setupNumLevels     = 100;
            mlOptions.setupNumAggLevels = 100;
            mlOptions.eliminationMaxDegree  = 2;
            %mlOptions.logLevel           = 2;
            mlSetup     = amg.setup.MultilevelSetup(mlOptions);
            setup       = mlSetup.build(problem);
            if (obj.logger.debugEnabled)
                disp(setup);
            end
            cycle = amg.solve.SolverLamgLaplacian.solveCycle(setup, problem.b, mlOptions);
            acf   = obj.acfComputer.run(problem, cycle);
            assertTrue(acf < 1e-10, '1-D grid with elimination levels should be an exact solver');
        end
        
        function testErdos972ExactElimination(obj)
            % Test Level 2 of the Erdos972 graph setup. Exact elimination
            % should lead to an exact solver (i.e. the two-level method
            % comprising of levels 2 and 3 should have ACF=0 at level 2).
            
            problem    = AmgTestUtil.loadProblem('lap/uf/Pajek/Erdos991/component-1');
            mlOptions  = amg.solve.UTestElimination.defaultOptions();
            mlOptions.setupNumAggLevels    = 10;
            mlOptions.setupNumLevels        = 4;
            mlOptions.eliminationMaxDegree  = 4;
            mlOptions.cycleDirectSolver     = 1;
            mlOptions.maxCoarseRelaxAcf     = 0.01;
            mlOptions.maxDirectSolverSize   = 10;
            %mlOptions.logLevel              = 2;
            mlOptions.numCycles             = 1;
            % Fix random seed
%             if (~isempty(mlOptions.randomSeed))
%                 setRandomSeed(mlOptions.randomSeed);
%             end
            
            % Set up phase
            mlSetup     = amg.setup.MultilevelSetup(mlOptions);
            setup = mlSetup.build(problem);
            if (obj.logger.debugEnabled)
                disp(setup);
            end
            
            % For easier 2-level debugging at level l=2, Run cycle at level
            % 2 on A*x=0 starting from x(t)=delta(t-s). Expecting x=0 after
            % the cycle, for any s.
            l = 2;
            fineLevel   = setup.level{l};
            n           = fineLevel.g.numNodes;
            s           = randi(n,1,1); %1421;
            x           = zeros(n,1);
            x(s)        = 1;
            
            mlCycle = amg.solve.SolverLamgLaplacian.solveCycle(setup, zeros(n,1), mlOptions, ...
                'finest', l);
            mlCycle.run(x, -fineLevel.A*x);
            %y = mlCycle.run(x);
            
%             assertTrue(isempty(find(abs(y) > eps, 1)), ...
%                 'Two-level elimination method must be an exact solver');
        end
    end
    
    %=========================== PRIVATE METHODS==========================
    methods (Access = private)
        function acf = eliminationNonHom(obj, key, numLevels)
            problem = AmgTestUtil.loadProblem(key);
            
            % Set up multigrid cycle
            mlOptions   = amg.solve.UTestElimination.defaultOptions();
            mlOptions.logLevel       = 2;
            mlOptions.numCycles = 1;
            mlOptions.setupNumLevels = numLevels;
            mlOptions.cycleDirectSolver     = 1;
            mlOptions.maxDirectSolverSize = 63;
            mlOptions.nuDefault = 1;
            mlOptions.minEliminationFraction    = 0.1;
            mlOptions.nuDesign = 'post';
            mlOptions.eliminationMaxDegree = 2;
            %mlOptions.setupNumAggLevels = 2;
            mlSetup     = amg.setup.MultilevelSetup(mlOptions);
            setup       = mlSetup.build(problem);
            if (obj.logger.debugEnabled)
                disp(setup);
            end
            finest = 1;
            %b = rand(setup.level{finest}.size,1);
            b = (1:setup.level{finest}.g.numNodes)';
            b = removeZeroModes(b, []);
            problem = lin.api.Problem(problem.A, b, problem.g);
            x0 = ones(setup.level{finest}.g.numNodes,1);
            %x0 = setup.level{finest}.A\b;
            cycle = amg.solve.SolverLamgLaplacian.solveCycle(setup, problem.b, mlOptions, 'finest', finest);
            [acf, dummy] = obj.acfComputer.run(problem, cycle, x0); %#ok
            clear dummy;
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
            mlOptions.cycleDirectSolver         = 1;
            mlOptions.numCycles                 = 20;
            mlOptions.errorNorm                 = @errorNormResidual;
            mlOptions.combinedIterates          = 1;
            mlOptions.setupNumAggLevels        = 100;
            mlOptions.cycleIndex                = 1.2;
            mlOptions.nuDesign                  = 'split_evenly';
            mlOptions.cycleType                 = 'cs';%'full'; % More efficient elimination implementation than 'cs'

            % Test vectors
            mlOptions.tvNum                     = 10;
            mlOptions.tvSweeps                  = 5;
            
            % Aggregation
            mlOptions.aggregationType           = 'limited';
            %mlOptions.aggregationUpdate         = 'local-relax';
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
            printer         = printerFactory.newInstance('text', result, 1);
            printer.addIndexColumn('#', 3);
            printer.addColumn('Group'    , 's', 'field'   , 'metadata.key',         'width', 30);
            printer.addColumn('#Nodes'   , 'd', 'field'   , 'metadata.numNodes',   	'width',  8);
            printer.addColumn('#Edges'   , 'd', 'field'   , 'metadata.numEdges',   	'width',  9);
            printer.addColumn('HCR'      , 'f', 'field'   , 'data(6)',              'width',  7, 'precision', 3);
            printer.addColumn('ACF'      , 'f', 'field'   , 'data(1)',             	'width',  7, 'precision', 3);
            printer.addColumn('Work'     , 'f', 'field'   , 'data(4)',             	'width',  8, 'precision', 2);
            printer.addColumn('#lev'     , 'd', 'field'   , 'data(5)',             	'width',  5);
            printer.run();
        end
        
    end
end
