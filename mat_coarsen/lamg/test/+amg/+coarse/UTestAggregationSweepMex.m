classdef (Sealed) UTestAggregationSweepMex < amg.AmgFixture
    %UTestAggregationSweepMex Unit test of the aggregationsweep MEX
    %implementation.
    %   This class tests the aggregationsweep.c MEX function correctness
    %   within the lowDegreeNodes() method.
    %
    %   See also: LOWDEGREENODES.
    
    %=========================== PROPERTIES ==============================
    properties (Constant, GetAccess = protected)
        logger = core.logging.Logger.getInstance('amg.coarse.UTestAggregationSweepMex')
    end
    
    %=========================== CONSTRUCTORS ============================
    methods
        function obj = UTestAggregationSweepMex(name)
            %UTestAggregationSweepMex Constructor
            %   UTestAggregationSweepMex(name) constructs a test case using
            %   the specified name.
            obj = obj@amg.AmgFixture(name);
        end
    end
    
    %=========================== TESTING METHODS =========================
    methods
        function testGrid2d(obj)
            % Test that MEX code and slower MATLAB code produce the same
            % result for a 2-D Laplacian problem.

            % Easy to analyze as a first example
            n = [5 5];
            if (obj.logger.debugEnabled)
                obj.logger.debug('Testing 2-D grid %dx%d\n', n);
            end
            g = Graphs.grid('fd', n);
            obj.compareAggregations(g);
        end
        
        % This test still fails!!!!!!
        function inactiveTestCaseWithWrongNumAggregates(obj)
            % Test a MEX code bug revealed by a test case: numAggregates
            % was less than the actual number of aggregates.
            
            g = Graphs.testInstance('lap/walshaw/coloring/inithx.i.1/component-1');
            obj.compareAggregations(g);
        end
    end
    
    %=========================== PRIVATE METHODS==========================
    methods (Access = private)
        function compareAggregations(obj, g)
            % Compare MEX code and slower MATLAB code.
            %----------------------------------------
            % Run m-code (slower but reliable)
            %----------------------------------------
            % Set random state for deterministic results
            randomSeed = 10;
            
            s = RandStream('mt19937ar','Seed', randomSeed);
            RandStream.setGlobalStream(s);
            runner = RunnerAggregator('aggregationType', 'limited', ...
                'aggregationUpdate', 'affinity-energy', ...
                'minCoarseSize', 10, ...
                'initialGuess', 'random', ...
                'deltaDecrement', 0.5, ...
                'generatePlots', false, ...
                'radius', 4 ...
                );
            tStart = tic;
            [data, details] = runner.run(g);
            tMatlab = toc(tStart);
            
            %----------------------------------------
            % Run mex code
            %----------------------------------------
            %disp('=================================================================');
            %disp('=================================================================');
            %disp('=================================================================');
            % Set random state for deterministic results
            s = RandStream('mt19937ar','Seed', randomSeed);
            RandStream.setGlobalStream(s);
            runner = RunnerAggregator('aggregationType', 'limited', ...
                'aggregationUpdate', 'affinity-energy-mex', ...
                'minCoarseSize', 10, ...
                'initialGuess', 'random', ...
                'deltaDecrement', 0.5, ...
                'generatePlots', false, ...
                'radius', 4 ...
                );
            tStart = tic;
            [dataMex, detailsMex] = runner.run(g);
            tMex = toc(tStart);

            assertEqual(data, dataMex);
            assertEqual(details.T, detailsMex.T);
            if (obj.logger.infoEnabled)
                obj.logger.info('Aggregation time: matlab=%f sec speedup=%f\n', ...
                    tMex, tMatlab, tMatlab/tMex);
            end
        end
    end
end
