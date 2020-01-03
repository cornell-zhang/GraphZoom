classdef (Sealed) UTestBatchRunner < graph.GraphFixture
    %UTestBatchLoader Unit test of writing graph batches to files.
    %   This class includes unit tests of Writers and related runners that
    %   save graphs to files.
    
    %=========================== PROPERTIES ==============================
    properties (Constant, GetAccess = private)
        logger          = core.logging.Logger.getInstance('graph.runner.UTestBatchRunner')
        MAX_EDGES       = 3000               % Maximum # edges in graphs of interest
    end
    
    %=========================== CONSTRUCTORS ============================
    methods
        function obj = UTestBatchRunner(name)
            %UTestBatchRunner Constructor
            %   UTestBatchRunner(name) constructs a test case using the
            %   specified name.
            obj = obj@graph.GraphFixture(name);
        end
    end
    
    %=========================== TESTING METHODS =========================
    methods
        function testRunGraphStats(obj)
            % Test a simple runner that loads graphs and computes simple
            % statistics of each.
            obj.graphStats(0, graph.runner.UTestBatchRunner.MAX_EDGES);
        end
   
    end
    
    %=========================== PRIVATE METHODS =========================
    methods (Access = private)
    end
    
end
