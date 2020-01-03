classdef (Sealed) UTestCycleAcfGrid1d < amg.AmgFixture
    %UTestCycleAcf Unit test two-level and multi-level cycle ACF for the
    %1-D grid graph.
    %   This class computes cycle ACFs on the basic example of a 1-D
    %   Laplacian with Neumann B.C. (1-D grid graph).
    
    %=========================== PROPERTIES ==============================
    properties (Constant, GetAccess = protected)
        logger          = core.logging.Logger.getInstance('amg.solve.UTestCycleAcfGrid1d')
    end
    %     properties (GetAccess = private, SetAccess = private)
    %         problem         % 1-D grid test problem
    %     end
    
    %=========================== CONSTRUCTORS ============================
    methods
        function obj = UTestCycleAcfGrid1d(name)
            %UTestCycleAcfGrid1d Constructor
            %   UTestCycleAcfGrid1d(name) constructs a test case using the
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
        function testTwoLevelAcf(obj)
            % Compute two-level ACF.
            
            % Generate a normalized 1-D grid Laplacian
            N   = 40;
            g   = Graphs.grid('fd', N, 'normalized', true);
            
            % Run two-level cycles and compute ACF
            mlOptions                       = amg.solve.UTestCycleAcfGrid1d.defaultOptions();
            mlOptions.tvNum                 = 5;
            mlOptions.tvSweeps              = 10;
            mlOptions.nuDefault             = 4;
            mlOptions.energyCorrectionType  = 'ls-sum';
            
            solver = Solvers.newSolver('lamg', mlOptions, ...
                'steadyStateTol', 1e-5, 'output', 'full', ...
                'errorReductionTol', 1e-30, ...
                'numIters', 2);
            runner = lin.runner.RunnerSolver(@Problems.laplacianHomogeneous, 'lamg', solver);
            runner.solverContext = lin.runner.SolverContext;
            [dummy, details] = runner.run(g); %#ok
            
            % Report results
%             if (obj.logger.infoEnabled)
%                 obj.logger.info('N = %3d   ACF = %.3f\n', N, result(1));
%             end
            if (obj.logger.debugEnabled)
                % Asymptotic vector
                figure(100);
                if (numel(N) == 1)
                    plot(details.asymptoticVector, 'bx-');
                elseif (numel(N) == 2)
                    surf(reshape(details.asymptoticVector, N))
                end
                title('2-level Cycle Asymptotic vector');
            end
        end
        
        function testGrid1d(obj)
            % Test loading cycle ACF for a 2-D grid graph.
            %global GLOBAL_VARS;
            
            batchReader = graph.reader.BatchReader;
            dim = 1;
            N   = 40; %40*2.^(0:4);
            for n = N
                g = Graphs.grid('fd', ones(dim,1)*n, 'normalized', true); % Normalized Laplacian
                %eigs(g.laplacian, 5, 'sm') %TODO: move eigenvalue test to
                %a separate Generator test suite
                batchReader.add('graph', g);
            end
            
            % Run cycles on graphs in a batch run
            mlOptions                           = amg.solve.UTestCycleAcfGrid1d.defaultOptions();
            %mlOptions.setupNumAggLevels            = 2;
            mlOptions.tvNum                     = 5;
            mlOptions.tvSweeps                  = 10;
            mlOptions.energyCorrectionType      = 'ls-sum';
            mlOptions.nuMin = 2;
            % Testing - fix aggregation to control ACF and focus on energy
            % correction debugging
            %mlOptions.nuDefault = 2; mlOptions.nuOptimization = false;
            mlOptions.maxAggregationStages  = 1;
            
            solver = Solvers.newSolver('lamg', mlOptions, ...
                'steadyStateTol', 1e-2, 'output', 'full');
            runner = lin.runner.RunnerSolver(@Problems.laplacianHomogeneous, 'lamg', solver);
            runner.solverContext = lin.runner.SolverContext;

            result          = amg.AmgFixture.BATCH_RUNNER.run(batchReader, runner);
            % Report results
            if (obj.logger.infoEnabled)
                amg.solve.UTestCycleAcfGrid1d.printResults(result);
            end
            % Asymptotic vector
            %             figure(100);
            %             plot(result.details{1}.asymptoticVector, 'bx-');
        end
        
        function inactiveTestTwoLevelVsPropagator(obj) % Obsolete test
            % Compare two-level cycle action with the propagator matrix
            % action. Assuming the cycle is using a debug mode with g=2
            % energy correction values at all points.
            
            % Graph
            N = 40*2.^(0:2);
            for n = N
                problem     = AmgTestUtil.newGridProblem(n, 'normalized', true);
                % Set up multigrid cycle
                mlOptions   = amg.solve.UTestCycleAcfGrid1d.defaultOptions();
                mlOptions.setupSave = true;
                mlSetup     = amg.setup.MultilevelSetup(mlOptions);
                setup       = mlSetup.build(problem);
                cycle       = amg.solve.Cycle(problem, setup, mlOptions);
                % Propagator
                g           = 2;
                M           = twoLevelOperator(setup, mlOptions.nuDefault, g);
                
                % Compute asymptotic convergence factor = spectral radius
                % of M
                opts.tol = 1e-3;
                d = abs(eigs(M, 1, 'LM', opts));
                if (obj.logger.debugEnabled)
                    obj.logger.debug('n = %4d   Predicted ACF=%.3f\n', n, d);
                end
            end
            
            % Compare actions on a random vector
            x0  = randInRange(-1.0, 1.0, n, 1);
            x   = cycle.run(x0);
            y   = M*x0;
            err = max(abs(x-y))./max(abs(x));
            if (obj.logger.debugEnabled)
                obj.logger.debug('Random x     action difference = %.3e\n', err);
            end
            assertTrue(err < 1e-13);
            
            % Compare actions on the constant vector
            x0  = ones(n,1);
            x   = cycle.run(x0);
            y   = M*x0;
            err = max(abs(x-y))./max(abs(x0));
            err2 = max(abs(x));
            if (obj.logger.debugEnabled)
                obj.logger.debug('Constant x   action difference = %.3e\n', err);
                obj.logger.debug('Constant x   |Cycle(x)| = %.3e\n', err2);
            end
            assertTrue(err < 1e-13);
            assertTrue(err2 < 1e-13);
            %[x0 x]
            
            % Compare actions on the second eigenvector of M
            [v, lam] = eigsort(M, 'descend');
            i = 2;
            x0  = v(:,i);
            x   = cycle.run(x0);
            y   = M*x0;
            err = max(abs(x-y))./max(abs(x));
            if (obj.logger.debugEnabled)
                obj.logger.debug('x = v2       action difference = %.3e\n', err);
            end
            assertTrue(err < 1e-13);
            
            % Test that Cycle(x0) = lambda*x0
            z = x/lam(i);
            %[x0 x x./x0] lam(i)
            err = max(abs(x0-z))./max(abs(x0));
            if (obj.logger.debugEnabled)
                obj.logger.debug('|Cycle(v2)/lam2 - v2|/|v2|     = %.3e\n', err);
            end
            assertTrue(err < 1e-12);
        end
        
    end
    
    %=========================== PRIVATE METHODS==========================
    methods (Static, Access = private)
        function printResults(result)
            % Print results to standard output (fid=1)
            printerFactory  = graph.printer.PrinterFactory;
            printer         = printerFactory.newInstance('text', result, 1);
            printer.addIndexColumn('#', 3);
            printer.addColumn('Group'   , 's', 'field'   , 'metadata.key',          'width', 30);
            printer.addColumn('#Nodes'  , 'd', 'field'   , 'metadata.numNodes',   	'width',  8);
            printer.addColumn('#Edges'  , 'd', 'field'   , 'metadata.numEdges',   	'width',  9);
            printer.addColumn('ACF'     , 'f', 'field'   , 'data(1)',             	'width',  7, 'precision', 2);
            printer.run();
        end
        
        function options = defaultOptions()
            % Default two-level options.
            options = amg.api.Options;
            
            % Setup options
            options.setupNumAggLevels      = 2;
            options.elimination             = false;
            options.tvNum                   = 5;
            options.tvSweeps                = 5;
            %options.tvInitialGuess         = 'geometric';
            % Force a 1:2 coarse grid
            options.minAggregationStages    = 1;
            options.maxAggregationStages    = 1;
            options.nuOptimization          = false;
            options.nuDesign                = 'post';
            options.nuDefault               = 2;
            options.energyCorrectionType    = 'constant';
            
            options.cycleDirectSolver       = 1;
            options.cycleMaxCoarsestSweeps  = 200;
            options.numCycles               = 20;
            options.errorNorm               = @errorNormResidual;
            %options.setupSave               = true;
            options.logLevel                = 1; %2;
        end
    end
end
