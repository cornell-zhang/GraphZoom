classdef (Sealed) RunnerSimpleStats < graph.runner.Runner
    %RUNNERSIMPLESTATS A runner that computes simple graph statistics.
    %   This class computes some descriptive meta data of a graph.
    %
    %   See also: RUNNER.
    
    %=========================== PROPERTIES ==============================
    properties (Constant, GetAccess = private)
        logger = core.logging.Logger.getInstance('graph.runner.RunnerSimpleStats')
    end
    
    %======================== IMPL: Runner ============================
    methods
        function fieldNames = fieldNames(obj) %#ok<MANU>
            % Return a cell array of result element labels.
            % TODO: refactor this class to a Printer and only use this
            % class to copy simple graph statistics from the meta data
            % object
            fieldNames = { 'numEdges' };  % Outputting # edges for now
        end
        
        function [result, details, updatedGraph] = run(obj, graph, dummy) %#ok
            % Print a table row with graph statistics. Return the graph's meta data object.
            tStart = tic;
            md = graph.metadata;
            result = md.numEdges; % Outputting # edges for now
            tElapsed = toc(tStart);
            
            % Save time it took to run
            details = struct();
            details.time = tElapsed;

            updatedGraph = [];
        end
        
        function needsGraph = needsGraph(obj) %#ok<MANU>
            % Does this runnuer need the fully-loaded graph instance or just
            % graph.metadata.
            needsGraph = false;
        end
    end
end

