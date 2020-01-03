classdef (Sealed) UTestAggregator < amg.AmgFixture
    %UTestAlgebraicDistance Unit test of computing algebraic distances.
    %   This class computes algebraic distances for various graph
    %   instances. This is a prerequisite of selecting a good coarse set
    %   using HCR.
    
    %=========================== PROPERTIES ==============================
    properties (Constant, GetAccess = protected)
        logger = core.logging.Logger.getInstance('amg.coarse.UTestAggregator')
    end
    
    %=========================== CONSTRUCTORS ============================
    methods
        function obj = UTestAggregator(name)
            %UTestAggregator Constructor
            %   UTestAggregator(name) constructs a test case using the
            %   specified name.
            obj = obj@amg.AmgFixture(name);
        end
    end
    
    %=========================== SETUP METHODS ===========================
    
    %=========================== TESTING METHODS =========================
    methods
        function testAggregation(obj)
            % Test aggregating graph nodes.
            
            % Easy to analyze as a first example
            n = [20 20];
            if (obj.logger.debugEnabled)
                obj.logger.debug('Testing 2-D grid %dx%d\n', n);
            end
            g = Graphs.grid('fd', n);
            %g = Graphs.grid('fd', [4 4]);
            
            % Set random state for deterministic results
            s = RandStream('mt19937ar','Seed', 1);
            RandStream.setGlobalStream(s);
            
            runner = RunnerAggregator('aggregationType', 'limited', ...
                'aggregationUpdate', 'affinity-energy', ...
                'minCoarseSize', 10, ...
                'initialGuess', 'random', ...
                'deltaDecrement', 0.5, ...
                'generatePlots', false, ...
                'radius', 4 ...
                );
            [data, details] = runner.run(g);
            if (obj.logger.debugEnabled)
                disp(data);
                disp(details);
            end
        end
    end
    
    %=========================== PRIVATE METHODS==========================
    methods (Static, Access = private)
    end
end
