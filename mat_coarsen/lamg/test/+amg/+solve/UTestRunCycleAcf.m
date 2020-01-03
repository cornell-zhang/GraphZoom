classdef (Sealed) UTestRunCycleAcf < amg.AmgFixture
    %UTestRunCycleAcf Unit test of cycle ACF batch run.
    %   This class tests the runCycleAcf() function.
    %
    %   See also runCycleAcf.
    
    %=========================== PROPERTIES ==============================
    properties (Constant, GetAccess = protected)
        logger          = core.logging.Logger.getInstance('amg.solve.UTestRunCycleAcf')
    end
    
    %=========================== CONSTRUCTORS ============================
    methods
        function obj = UTestRunCycleAcf(name)
            %UTestRunCycleAcf Constructor
            %   UTestRunCycleAcf(name) constructs a test case using the
            %   specified name.
            obj = obj@amg.AmgFixture(name);            
        end
    end

    %=========================== TESTING METHODS =========================
    methods
        function testRunCycleAcf(obj) %#ok<MANU>
            % Make sure the batch program works for a small test graph.

            g = Graphs.testInstance('lap/uf/Pajek/GD97_a');
            [r, dummy1, dummy2] = Solvers.runSolvers('graph', g, 'solvers', {'lamg'}, 'print', false, 'clearWhenDone', false); %#ok
            assertTrue(abs(r.details{1}{1}.acf) < 1e-12, 'Small graph should be solved with a direct solver and have ACF = 0');
        end
        
        function testTwoLevelAcf(obj) %#ok<MANU>
            % Make sure the two-level ACF test program works for a small
            % test graph.

            g = Graphs.testInstance('lap/uf/Pajek/Erdos991/component-1');
            [dummy1, s, dummy2] = Solvers.runSolvers('graph', g, 'solvers', {'lamg'}, 'print', false, 'clearWhenDone', false, ...
                'maxCoarseRelaxAcf', 0.01, 'maxDirectSolverSize', 10, 'setupNumLevels', 4, ...
                'clearWhenDone', false, 'dieOnException', true); %#ok
            assertTrue(s{1}.setup.numLevels >= 3, 'Expecting at least 3 levels');
            twoLevelAcf(s{1}.setup, 2, 3, [], [], 'print', false);
        end
        
        function testSunTreament(obj) %#ok<MANU>
            % Test that sun nodes are correctly treated. We compare the
            % following test cases:
            % (A) Sun graph with no elimination should be produce a single
            % aggregate.
            % (B) Complete sub-graph added to a grid (with no possible
            % elimination) should aggregate the entire sub-graph into a
            % single aggregate.

            g = Graphs.sun(1000);
            [r, s, dummy] = Solvers.runSolvers('eliminationMaxDegree', 0, ...
                'graph', g, 'solvers', {'lamg'}, 'clearWhenDone', false, 'randomSeed', 1, ...
                'print', false); %#ok
            h = s{1}.setup;
            assertTrue(h.numLevels == 2, 'Sun graph: expecting exactly 2 levels');
            assertTrue(h.level{2}.g.numNodes == 1, 'Sun graph: expecting a single coarse-level aggergate');
            assertTrue(abs(r.details{1}{1}.acf) < 1e-12, 'Sun graph should have ACF = 0');

            g = Graphs.pathPlusComplete(100, 500, 100);
            [r, s, dummy] = Solvers.runSolvers('eliminationMaxDegree', 0, ...
                'graph', g, 'solvers', {'lamg'}, 'clearWhenDone', false, 'randomSeed', 1, ...
                'print', false); %#ok
            h = s{1}.setup;
            assertTrue(h.numLevels >= 2, 'Grid+complete sub-graph: expecting at least 2 levels');
            assertTrue(h.edges(2)/h.edges(1) < 0.25, 'Grid+complete sub-graph: expecting a large reduction in edges in the first coarsening stage');
            assertTrue(abs(r.details{1}{1}.acf) < 0.25, 'Grid+complete sub-graph should have a good ACF');
        end
    end
    
    %=========================== PRIVATE METHODS==========================
end
