classdef (Sealed) UTestBatchReader < graph.GraphFixture
    %UTestBatchReader A unit test of class BatchReader.
    %   This class includes unit tests of Class BatchReader's batch build and
    %   read operations.
    
    %=========================== PROPERTIES ==============================
    properties (Constant, GetAccess = protected)
        logger = core.logging.Logger.getInstance('graph.reader.UTestBatchReader')
    end
    properties (GetAccess = protected)
        batchReader             % Instance to test
    end
    
    %=========================== CONSTRUCTORS ============================
    methods
        function obj = UTestBatchReader(name)
            %UTestBatchReader Constructor
            %   UTestBatchReader(name) constructs a test case using the
            %   specified name.
            obj = obj@graph.GraphFixture(name);
        end
    end
    
    %=========================== SETUP METHODS ===========================
    methods
        
        function setUp(obj)
            %setUp Simple test fixture setup.
            setUp@graph.GraphFixture(obj);
            obj.batchReader = graph.reader.BatchReader;
        end
        
        function tearDown(obj)
            %tearDown Simple test fixture tear-down.
            obj.batchReader = [];
        end
        
    end
    
    %=========================== TESTING METHODS =========================
    methods
        function testReadUfFormatById(obj)
            % Test adding UF instances with specified IDs and removing
            % instances.
            
            obj.batchReader.add('formatType', graph.api.GraphFormat.UF, 'id', [1494, 1495]');
            obj.batchReader.add('formatType', graph.api.GraphFormat.UF, 'id', 1493);
            obj.batchReader.add('formatType', graph.api.GraphFormat.UF, 'id', [1491, 1492]);
            assertEqual(obj.batchReader.size, 5);
            
            % Keys are sorted ==> 1493 is the third key. 1493 is an
            % undirected problem ==> must have 0-diagonal adjacency matrix
            g = obj.batchReader.read(3);
            assertEqual(g.metadata.id, 1493);
            assertTrue(isempty(find(diag(g.adjacency), 1)));
            
            % Remove instance
            metadata = obj.batchReader.getMetadata(3);
            obj.batchReader.removeMetadata(metadata);
            assertEqual(obj.batchReader.size, 4);
        end
        
        function testReadUfFormatByType(obj)
            % Test loading all undirected UF graphs.
            
            obj.batchReader.add('formatType', graph.api.GraphFormat.UF, ...
                'type', graph.api.GraphType.UNDIRECTED, ...
                'keywords', {'undirected', 'graph'});
            sz = obj.batchReader.size;
            assertTrue(sz >= 100);
            
            % Metadata keys are unique, but reader allows duplicate keys;
            % 1493 was already added before, but size should be incremented
            % upon adding it again.
            obj.batchReader.add('formatType', graph.api.GraphFormat.UF, 'id', 1493);
            assertEqual(obj.batchReader.size, sz+1);
        end
        
        function testReadChacoFormatFromFile(obj)
            % Test adding a small instance from file in Chaco format.
            global GLOBAL_VARS;
            
            obj.batchReader.add('group', 'walshaw', ...
                'file', [GLOBAL_VARS.data_dir '/walshaw/uk.chaco']);
            
            % Test loading graph from Chaco format
            g = obj.batchReader.read(1);
            assertTrue(isempty(find(diag(g.adjacency), 1)));
        end
        
        function testReadDimacsFormatUnweighted(obj)
            % Test adding a small unweighted instance from file in DIMACS format.
            global GLOBAL_VARS;
            
            obj.batchReader.add('group', 'walshaw/coloring', ...
                'file', [GLOBAL_VARS.data_dir '/walshaw/coloring/jean.dimacs']);
            
            % Test loading graph from Chaco format
            g = obj.batchReader.read(1);
            assertTrue(isempty(find(diag(g.adjacency), 1)));
        end
        
        function testReadDimacsFormatWeighted(obj)
            % Test adding a small weighted graph instance from file in DIMACS format from
            % Ilya Safro's ANL collection.
            global GLOBAL_VARS;
            
            obj.batchReader.add('group', 'ilya', ...
                'file', [GLOBAL_VARS.data_dir '/ilya/add32.dimacs']);
            
            % Test loading graph from Chaco format
            g = obj.batchReader.read(1);
            assertTrue(isempty(find(diag(g.adjacency), 1)));
        end

        function testReadDimacsFormatProblematicIlyaInstance(obj)
            % A specific Ilya instance that seems to not be loaded
            global GLOBAL_VARS;
            
            obj.batchReader.add('group', 'ilya', ...
                'file', [GLOBAL_VARS.data_dir '/ilya/Peko01.dimacs']);
            
            % Test that adjacency matrix has at least one non-zero entry
            g = obj.batchReader.read(1);
            assertTrue(~isempty(find(g.adjacency, 1)));
        end
           
        function testReadDirectoryWithExtension(obj)
            % Test adding all instances from a directory. Input
            % files are assumed to be in Chaco format.
            global GLOBAL_VARS;
            
            obj.batchReader.add('dir', [GLOBAL_VARS.data_dir '/walshaw'], ...
                'extension', 'graph');
            assertTrue(obj.batchReader.size >= 40);
        end
        
        function testReadDirectory(obj)
            % Test adding all instances from a directory. Input
            % files are assumed to be in Chaco format.
            global GLOBAL_VARS;
            
            obj.batchReader.add('dir', [GLOBAL_VARS.data_dir '/walshaw']);
            assertTrue(obj.batchReader.size >= 40);
        end
        
        function testGraphWithDisconnectedNodes(obj)
            % A graph that has disconnected nodes that need to be removed.

            obj.batchReader.add('formatType', graph.api.GraphFormat.UF, 'id', 1493);
            % Original graph has 47 nodes, 1 disconnected
            g = obj.batchReader.read(1);
            assertEqual(g.numNodes, 46);
        end
    end
    
    %=========================== PRIVATE METHODS =========================
    methods (Access = private)
    end
    
end
