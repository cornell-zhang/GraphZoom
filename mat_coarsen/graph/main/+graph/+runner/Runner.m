classdef Runner < handle
    %RUNNER A functor of a graph problem.
    %   This interface runs some code on a GRAPH instance and returns
    %   numerical results. Usually used in conjunction of a BATCHRUNNER.
    %
    %   See also: GRAPH, BATCHRUNNER.
    
    %======================== METHODS =================================
    methods (Abstract)
        fieldNames = fieldNames(obj)
        % Return a cell array of labels corresponding to the elements of
        % the return value of result().
        
        [result, details, updatedRunner] = run(obj, graph, attributes)
        % Run on a GRAPH instance and return a numerical array RESULT. The
        % ATTRIBUTES struct contains additional meta data about this run
        % (e.g. run number in a batch run). DETAILS is an optional object
        % (usually a struct) for holding additional details about the run.
    end
    
    methods
        function result = runBefore(obj, dummy) %#ok
            % Intended to run once, before running on any graph instance. A
            % stub. The ATTRIBUTES struct contains additional meta data
            % about this run (e.g. number of runs in a batch run).
            result = [];
        end
        
        function result = runAfter(obj, dummy) %#ok
            % Intended to run once, after running on all graph instance. A
            % stub. The ATTRIBUTES struct contains additional meta data
            % about this run (e.g. number of runs in a batch run).
            result = [];
        end
        
        function needsGraph = needsGraph(obj) %#ok<MANU>
            % Does this runnuer need the fully-loaded graph instance or just
            % graph.metadata. Default: true. Override with false to speed
            % up batch runs of simple runners.
            needsGraph = true;
        end
    end
end
