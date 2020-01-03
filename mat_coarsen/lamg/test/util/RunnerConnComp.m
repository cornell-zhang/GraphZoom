classdef (Sealed) RunnerConnComp < graph.runner.Runner
    %RUNNERSIMPLESTATS A runner that computes graph connected components.
    %   This class computes some descriptive meta data related to graph
    %   components.
    %
    %   See also: RUNNER.
    
    %=========================== PROPERTIES ==============================
    properties (Constant, GetAccess = private)
        logger = core.logging.Logger.getInstance('RunnerConnComp')
    end
    
    %======================== IMPL: Runner ============================
    methods
        function fieldNames = fieldNames(obj) %#ok<MANU>
            % Return a cell array of result element labels.
            % TODO: refactor this class to a Printer and only use this
            % class to copy simple graph statistics from the meta data
            % object
            fieldNames = { 'numComponents' };  % Outputting # edges for now
        end
        
        function [result, details, updatedGraph] = run(obj, g, dummy) %#ok
            % Print a table row with graph statistics. Return the graph's meta data object.

            % If we have a function for computing the number of
            % connected components, use it, otherwise use our slower function
            result = max(components(g.adjacency));
            details = struct();
            updatedGraph = [];
        end
    end
end
