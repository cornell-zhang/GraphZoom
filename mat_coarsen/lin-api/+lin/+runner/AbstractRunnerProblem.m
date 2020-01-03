classdef AbstractRunnerProblem < graph.runner.Runner
    %ABSTRACTRUNNERPROBLEM Run on a graph problem.
    %   This Runner template implementation sets up a graph Problem
    %   instance for a graph G and runs on it.
    %
    %   See also: RUNNER, PROBLEM.
    
    %=========================== PROPERTIES ==============================
    properties (Constant, GetAccess = private)
        myLogger = core.logging.Logger.getInstance('lin.runner.AbstractRunnerProblem')
    end
    
    properties (GetAccess = protected, SetAccess = private) % Dependencies
        problemFactory          % A functor that sets up problems from graphs
    end
    
    %======================== CONSTRUCTORS ============================
    methods (Access = protected)
        function obj = AbstractRunnerProblem(problemFactory)
            % Constructor.
            obj.problemFactory = problemFactory;
        end
    end
    
    %======================== IMPL: Runner ============================
    methods (Sealed)
        function [data, details, updatedGraph] = run(obj, graph, varargin)
            % A template method that constructs a Problem from GRAPH and
            % runs on it.
            if (numel(varargin) < 1)
                attributes = struct('width', 0);
            else
                attributes = varargin{1};
            end
            problem = obj.problemFactory(graph);
            g = problem.g;
            if (obj.myLogger.infoEnabled)
                obj.myLogger.info(sprintf(sprintf('%%-%ds', 11+2*attributes.width), 'Processed'));
                obj.myLogger.info('%-30s numNodes=%6d numEdges=%8d\n', ...
                    g.metadata.toString, ...
                    g.metadata.numNodes, g.metadata.numEdges);
            end
            [data, details] = obj.runOnProblem(problem);
            updatedGraph = problem.g;
        end
    end
    
    %======================== PRIVATE METHODS =========================
    methods (Abstract, Access = protected)
        [data, details] = runOnProblem(obj, problem)
        % A hook that runs on the problem PROBLEM.
    end
end
