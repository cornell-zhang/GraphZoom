classdef (Sealed) UTestPump < graph.GraphFixture
    %UTestBatchLoader Unit test of writing graph batches to files using a
    %data pump.
    %   This class includes unit tests of Writers and related runners that
    %   save graphs to files.
    
    %=========================== PROPERTIES ==============================
    properties (Constant, GetAccess = protected)
        logger          = core.logging.Logger.getInstance('graph.runner.UTestPump')
        MAX_EDGES       = 3000            % Maximum # edges in graphs of interest
    end
    
    %=========================== CONSTRUCTORS ============================
    methods
        function obj = UTestPump(name)
            %UTestBatchWriter Constructor
            %   UTestBatchWriter(name) constructs a test case using the
            %   specified name.
            obj = obj@graph.GraphFixture(name);
        end
    end
    
    %=========================== TESTING METHODS =========================
    methods
        function testPump(obj)
            % Test loading graphs in any format saving them to files in MAT
            % format using a Pump.
            global GLOBAL_VARS;
            
            if (obj.logger.infoEnabled)
                obj.logger.info('\n');
            end
            
            % Load graphs
            batchReader = graph.reader.BatchReader;
            batchReader.add('formatType', graph.api.GraphFormat.UF, ...
                'type', graph.api.GraphType.UNDIRECTED, ...
                'keywords', {'undirected', 'graph'});
            batchReader.add('dir', [GLOBAL_VARS.data_dir '/walshaw']);
            batchReader.add('dir', [GLOBAL_VARS.data_dir '/ilya']);
            
            % Run data pump
            outputDir = [tempdir 'mat'];
            % Clean previous experiments
            if (exist(outputDir, 'dir'))
                rmdir(outputDir, 's');
            end
            pump = graph.runner.Pump(batchReader);
            pump.maxEdges = graph.runner.UTestPump.MAX_EDGES;
            pump.run(outputDir);
            
            % Load MAT format from the temp dir and test that everything
            % was loaded
            matReader = graph.reader.BatchReader;
            matReader.add('dir', outputDir);
            smallGraphs = graph.api.GraphUtil.getGraphsWithEdgesBetween(...
                batchReader, 0, pump.maxEdges);
            assertEqual(matReader.size, numel(smallGraphs));
        end
    end
    
    %=========================== PRIVATE METHODS =========================
    methods (Access = private)
    end
    
end
