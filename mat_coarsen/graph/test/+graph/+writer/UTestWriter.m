classdef (Sealed) UTestWriter < graph.GraphFixture
    %UTestBatchLoader Unit test of graph writers.
    %   This class includes unit tests of writing graphs in various output
    %   formats.
    
    %=========================== PROPERTIES ==============================
    properties (Constant, GetAccess = protected)
        logger          = core.logging.Logger.getInstance('graph.writer.UTestWriter')
        WRITER_FACTORY  = graph.writer.WriterFactory();
    end
    
    %=========================== CONSTRUCTORS ============================
    methods
        function obj = UTestWriter(name)
            %UTestBatchWriter Constructor
            %   UTestBatchWriter(name) constructs a test case using the
            %   specified name.
            obj = obj@graph.GraphFixture(name);
        end
    end
    
    %=========================== TESTING METHODS =========================
    methods
        function testWriterDot(obj) %#ok<MANU>
            % Test writing a graph to a dot file.
            
            % Input parameters
            batchReader = graph.reader.BatchReader;
            batchReader.add('formatType', graph.api.GraphFormat.UF, 'id', 1493);
            outputFile = [tempdir 'graph/uf1493.png'];

            % Load the graph
            g           = batchReader.read(1);
            % Load image into workspace
            a = graphPlot(g, outputFile);
            assertTrue(~isempty(a));
            
            % Display graph image
%             image(a); 
%             axis image;
            
            % Clean up
%            delete(outputFile);
        end
    end
    
    %=========================== PRIVATE METHODS =========================
    methods (Access = private)
    end
    
end
