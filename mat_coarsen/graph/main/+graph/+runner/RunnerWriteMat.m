classdef (Sealed) RunnerWriteMat < graph.runner.Runner
    %RUNNERWRITEMAT A runner that writes the graph to file in MAT format.
    %   This class is useful for graph format conversion. Use a READER to
    %   load it and this runner to save it in MAT format, which is the
    %   easiest for MATLAB to deal with.
    %
    %   See also: RUNNER.
    
    %=========================== PROPERTIES ==============================
    properties (Constant, GetAccess = private)
        logger = core.logging.Logger.getInstance('graph.runner.RunnerWriteMat')
    end
    
    properties (GetAccess = private, SetAccess = private)
        writerMat               % Graph instance MAT format writer
        outputDir               % Output directory
    end
    
    %=========================== CONSTRUCTORS ============================
    methods
        function obj = RunnerWriteMat(outputDir)
            %Runner constructor. Initializer writer.
            writerFactory       = graph.writer.WriterFactory();
            obj.writerMat       = writerFactory.newInstance(graph.api.GraphFormat.MAT);
            obj.outputDir       = outputDir;
        end
    end
    
    %======================== IMPL: Runner ===============================
    methods
        function fieldNames = fieldNames(obj) %#ok<MANU>
            % Return a cell array of result element labels.
            fieldNames = { 'success' };
        end
        
        function [result, details, updatedGraph] = run(obj, graph, dummy) %#ok
            % Save graph to a MAT file. Return a success flag.
            details = [];
            try
                if (isfield(graph.metadata.attributes, 'g'))
                    graph.metadata.attributes.g = [];
                    graph.metadata.attributes = rmfield(graph.metadata.attributes, 'g');
                end
                result = 1;
                file = [obj.outputDir '/' graph.metadata.group '/' graph.metadata.name '.mat'];
                if (obj.logger.debugEnabled)
                    obj.logger.debug('Saving to file %s: numNodes=%d, numEdges=%d\n', file, ...
                        graph.metadata.numNodes, graph.metadata.numEdges);
                end
                obj.writerMat.write(graph, file);
            catch e
                result = 0;
                details.error = e;
            end
            
            updatedGraph = [];
        end
    end
end

