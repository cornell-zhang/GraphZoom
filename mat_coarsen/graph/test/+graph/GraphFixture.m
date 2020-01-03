classdef GraphFixture < TestCase
    %GRAPHFIXTURE Graph module test fixture.
    %   Use as a base class for test classes. Contains common testing
    %   set-up and tear-down and utility methods.
    
    %=========================== PROPERTIES ==============================
    properties (Constant, GetAccess = private)
        log          = core.logging.Logger.getInstance('graph.GraphFixture')
        BATCH_RUNNER    = graph.runner.BatchRunner;
    end
    
    %=========================== FIELDS ==================================
    
    %=========================== CONSTRUCTORS ============================
    methods
        function obj = GraphFixture(name)
            %GraphFixture Constructor
            %   PetKineticFixture(name) constructs a test case with the
            %   specified name.
            obj = obj@TestCase(name);
        end
    end
    
    %=========================== SETUP METHODS ===========================
    methods
        function setUp(self) %#ok<MANU>
            % Initialize configuration.
            config;
        end
        
        function tearDown(self) %#ok<MANU>
            %tearDown Simple test fixture tear-down.
            %             obmeta = metaclass(self); fprintf('tearDown()
            %             %s\n', obmeta.Name);
        end
    end
    
    %=========================== PRIVATE METHODS =========================
    methods (Access = protected, Sealed)
        function result = graphStats(obj, minEdges, maxEdges)
            % Test loading graphs in various input formats and return graph
            % statistics.
            global GLOBAL_VARS;
            
            if (obj.log.debugEnabled)
                obj.log.debug('\n');
            end
            
            batchReader = graph.reader.BatchReader;
            batchReader.add('formatType', graph.api.GraphFormat.UF, ...
                'type', graph.api.GraphType.UNDIRECTED, ...
                'keywords', {'undirected', 'graph'});
            batchReader.add('dir', [GLOBAL_VARS.data_dir '/walshaw']);
%            batchReader.add('dir', [GLOBAL_VARS.data_dir '/ilya']);
            assertTrue(batchReader.size >= 25);
            
            % Filter reader's list to small graphs only to reduce test
            % run-time
            smallGraphs = graph.api.GraphUtil.getGraphsWithEdgesBetween(batchReader, ...
                minEdges, maxEdges);
            
            % Create a table of graph statistics
            runner = graph.runner.RunnerSimpleStats;
            result = graph.GraphFixture.BATCH_RUNNER.run(batchReader, ...
                runner, smallGraphs);
        end
    end
end
