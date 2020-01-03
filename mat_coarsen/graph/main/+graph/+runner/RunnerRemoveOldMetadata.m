classdef (Hidden, Sealed) RunnerRemoveOldMetadata < graph.runner.Runner
    %RUNNERWRITEMAT A runner that remove obsolete metadata from a graph.
    %   This class is useful for fixing old graph instances. It removes the
    %   large field g.metadata.attributes.g and saves it in MAT format.
    %
    %   See also: RUNNER.
    
    %=========================== PROPERTIES ==============================
    properties (Constant, GetAccess = private)
        logger = core.logging.Logger.getInstance('graph.runner.RunnerRemoveOldMetadata')
    end
    
    properties (GetAccess = private, SetAccess = private)
        writer                  % Writes graphs to output dir
    end

    %=========================== CONSTRUCTORS ============================
    methods
        function obj = RunnerRemoveOldMetadata(outputDir)
            %Runner constructor. Initializer writer.
            obj.writer = graph.runner.RunnerWriteMat(outputDir);
        end
    end
    
    %======================== IMPL: Runner ===============================
    methods
        function fieldNames = fieldNames(obj) %#ok<MANU>
            % Return a cell array of result element labels.
            fieldNames = { 'success' };
        end
        
        function [result, details, updatedGraph] = run(obj, g, dummy) %#ok
            % Decomposte a graph G into components. Save each component to a
            % MAT file. Return a success flag.
            
            % Default output values
            result = 0;
            details = [];
            updatedGraph = [];
 
            % Write graph only if fixing it
            if (isfield(g.metadata.attributes, 'g'))
                %                 if (obj.logger.infoEnabled)
                %                     obj.logger.info('Fixing %s\n', g.metadata.key);
                %                 end
                g.metadata.attributes = rmfield(g.metadata.attributes, 'g');
                [result, details] = obj.writer.run(g);
            end
        end
    end
    
    %=========================== PRIVATE METHODS =========================
end