classdef (Sealed) BatchRunner < handle
    %BATCHRUNNER Graph problem batch runner.
    %   This class runs a functor (a RUNNER instance) on every problem in a
    %   collection of graphs loaded using a READER instance.
    %
    %   See also: GRAPH, GRAPHREADER, GRAPHRUNNER, BATCHRESULT.
    
    %=========================== PROPERTIES ==============================
    properties (Constant, GetAccess = private)
        logger = core.logging.Logger.getInstance('graph.runner.BatchRunner')
    end
    
    properties (GetAccess = private, SetAccess = public)
        checkPointFrequency = 0        % If set to a positive number, saves checkPoints every each checkPointFrequency runs
    end
    
    %======================== METHODS =================================
    methods
        function batchResult = run(obj, reader, runner, selectedIndices)
            % Loop over all graphs available from READER, and run RUNNER on
            % each one. The returned RESULTS is a cell array of the
            % individual RUNNER results. If SELECTEDINDICES is specified,
            % only these indices are loaded from the READER's problem list.
            
            global GLOBAL_VARS;
            
            % Prepare run
            if (nargin < 4)
                numRuns = reader.size;
                selectedIndices = 1:numRuns;
            else
                numRuns = numel(selectedIndices);
            end
            batchResult = graph.runner.BatchResult(numRuns, runner.fieldNames);
            if (obj.logger.infoEnabled)
                obj.logger.info('Batch running started, %d runs\n', numRuns);
            end
            if (obj.checkPointFrequency > 0)
                dt              = datestr(now, 'yyyy-mm-dd');
                id              = sprintf('%d',randi(100000));
                checkPointFile  = strcat(GLOBAL_VARS.out_dir, '/checkPoint/', dt, '/batch_result_checkPoint_', id, '.mat');
                if (obj.logger.infoEnabled)
                    obj.logger.info('Result checkPoint file = %s, updated every %d runs\n', checkPointFile, obj.checkPointFrequency);
                end
            end
            
            % Pre-processing
            attributes          = struct();
            attributes.numRuns  = numRuns;
            runner.runBefore(attributes);
            loadGraph           = runner.needsGraph;
            
            % Main loop on problems
            for index = 1:numRuns
                % Prepare run #i's attributes
                problemIndex            = selectedIndices(index);
                attributes.runIndex     = index;
                attributes.problemIndex = problemIndex;
                
                if (loadGraph)
                    % Fully load the graph instance
                    g                   = reader.read(problemIndex);
                else
                    % Fake a graph instance that only has a metadata field
                    g.metadata          = reader.getMetadata(problemIndex);
                end
                if (isempty(g))
                    obj.logger.warn('Failed to load graph for index=%d, skipping\n', index);
                    continue;
                end
                width = numDigits(numRuns);
                attributes.width = width;

                if (obj.logger.infoEnabled)
                    obj.logger.info(sprintf('Running %%%dd/%%%dd: ', width, width), ...
                        index, numRuns);
                    obj.logger.info('%-30s numNodes=%6d numEdges=%8d\n', ...
                        g.metadata.toString, ...
                        g.metadata.numNodes, g.metadata.numEdges);
                end
                
                % Run on graph g
                [data, details, updatedGraph] = runner.run(g, attributes);
                % g was updated during the run
                if (~isempty(updatedGraph))
                    g = updatedGraph;
                end
                
                % Free up memory
                metadata = g.metadata;
                metadata.attributes.g = [];
                clear g;
                %memory

                % Save results
                batchResult.metadata{index} = metadata;
                batchResult.data(index,:)   = data;
                batchResult.details{index}  = details;
                if ((obj.checkPointFrequency > 0) && (mod(index, obj.checkPointFrequency) == 0))
                    % Checkpoint save
                    if (obj.logger.infoEnabled)
                        obj.logger.info('Saving checkPoint\n');
                        create_dir(checkPointFile, 'file');
                        save(checkPointFile, 'batchResult');
                    end
                end
            end
            
            % Post-processing
            attributes.runIndex     = [];
            attributes.problemIndex = [];
            runner.runAfter(attributes);
        end
    end
end
