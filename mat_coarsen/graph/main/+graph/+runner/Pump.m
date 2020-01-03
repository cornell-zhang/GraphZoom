classdef (Sealed) Pump < graph.runner.Runnable
    %PUMP Data pump: converts any graph input format to MAT.
    %   This class converts the problem list of a BATCHREADER to MAT format
    %   and saves it under an output dir. The output dir is cleared before 
    %
    %   See also: BATCHRUNNER, WRITER.
    
    %=========================== PROPERTIES ==============================
    properties (Constant, GetAccess = private)
        BATCH_RUNNER    = graph.runner.BatchRunner;
        logger          = core.logging.Logger.getInstance('graph.runner.Pump')
    end
    properties % Options
        minEdges        = 0                 % Minimum # edges in saved graphs
        maxEdges        = 3000              % Maximum # edges in saved graphs
    end
    properties (GetAccess = private, SetAccess = private)
        batchReader             % Provides input instances
        writer                  % Outputs graphs to output dir
        outputDir               % Output dir
    end
     
    %=========================== CONSTRUCTORS ============================
    methods
        function obj = Pump(batchReader, outputDir, writer)
            %Pump Constructor.
            %   Pump(batchReader) constructs a pump that converts the
            %   problem list of batchReader to MAT format.
            obj.batchReader     = batchReader;
            obj.outputDir       = outputDir;
            obj.writer          = writer;
        end
    end
    
    %=========================== IMPL: Runnable ==========================
    methods
        function saveResults = run(obj)
            % Convert graphs to MAT format and save to the output
            % directory OUTPUTDIR.
            
            % Filter reader's list to small graphs only to reduce test
            % run-time
            smallGraphs = graph.api.GraphUtil.getGraphsWithEdgesBetween(...
                obj.batchReader, obj.minEdges, obj.maxEdges);
            if (obj.logger.infoEnabled)
                obj.logger.info('Truncating to %d graphs with %d to %d edges\n', ...
                    numel(smallGraphs), obj.minEdges, obj.maxEdges);
            end
            
            % Convert to MAT format and save under outputDir
            saveResults = graph.runner.Pump.BATCH_RUNNER.run(obj.batchReader, obj.writer, smallGraphs);
            index       = saveResults.fieldColumn('success');
            if (obj.logger.infoEnabled)
                obj.logger.info('Written %d graphs in MAT format to directory %s\n', ...
                    numel(find(saveResults.data(:,index))), obj.outputDir);
            end
        end
    end
    
    %=========================== PRIVATE METHODS =========================
    methods (Access = private)
    end
end
