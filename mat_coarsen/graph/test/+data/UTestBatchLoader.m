classdef (Sealed) UTestBatchLoader < graph.GraphFixture
    %UTestBatchLoader Unit test BatchLoader
    %   This class includes unit tests of Class BatchLoader building and
    %   loading operations.
    
    %=========================== PROPERTIES ==============================
    properties (Constant, GetAccess = protected)
        logger = core.logging.Logger.getInstance('graph.data.UTestBatchLoader')
    end
    properties (GetAccess = protected)
        batchLoader             % Instance to test
    end
    
    %=========================== CONSTRUCTORS ============================
    methods
        function obj = UTestBatchLoader(name)
            %UTestBatchLoader Constructor
            %   UTestBatchLoader(name) constructs a test case using the specified
            %   name.
            obj = obj@graph.GraphFixture(name);
        end
    end
    
    %=========================== SETUP METHODS ===========================
    methods
        
        function setUp(obj)
            %setUp Simple test fixture setup.
            obj.batchLoader = graph.data.BatchLoader;
        end
        
        function tearDown(obj)
            %tearDown Simple test fixture tear-down.
            obj.batchLoader = [];
        end
        
    end
    
    %=========================== TESTING METHODS =========================
    methods
        function testAddUfInstances(obj)
            % Test the graph incidence matrix against a known reference.

            obj.batchLoader.addUfInstances([1494, 1495]');
            obj.batchLoader.addUfInstances(1493);
            obj.batchLoader.addUfInstances([1491, 1492]);
            assertEqual(obj.batchLoader.size, 5);
            
            % 1493 is an undirected problem ==> must have 0-diagonal adjacency matrix
            graph = obj.batchLoader.load(3);
            assertEqual(graph.metadata.id, 1493);
            assertTrue(isempty(find(diag(graph.adjacency), 1)));
        end
    end
    
    %=========================== PRIVATE METHODS =========================
    methods (Access = private)
    end
    
end
