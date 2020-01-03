classdef (Sealed) RunnerConnectionEstimator < lin.runner.AbstractRunnerProblem
    %RUNNERCONNECTIONESTIMATOR Compute algebraic distances and connections.
    %   This class creates a single Level from a Problem instance,
    %   generates TVs and estimates node connections.
    %
    %   See also: CONNECTIONESTIMATOR, RELAX.
    
    %=========================== PROPERTIES ==============================
    properties (Constant, GetAccess = private)
        logger          = core.logging.Logger.getInstance('amg.util.RunnerConnectionEstimator')
    end
    
    properties (GetAccess = private, SetAccess = private)
        relaxFactory           % TV relaxation scheme (factory)
        connectionEstimator      % Estimates node connections (factory)
        options                  % Holds options specific to this object
    end
    
    %======================== CONSTRUCTORS ============================
    methods
        function obj = RunnerConnectionEstimator(problemType, ...
                relaxFactory, connectionEstimator, varargin)
            % Constructor.
            obj = obj@lin.runner.AbstractRunnerProblem(problemType, varargin);
            obj.relaxFactory            = relaxFactory;
            obj.connectionEstimator     = connectionEstimator;
        end
    end
    
    %======================== IMPL: Runner ===============================
    methods
        function fieldNames = fieldNames(obj) %#ok<MANU>
            % Return a cell array of method labels. The elements of the
            % data array returned from run() correspond to these labels.
            fieldNames = cell(1, 1);
            fieldNames{1} = 'connectionsPerNode';
        end
    end
    
    %======================== Impl: RunnerProblem ========================
    methods (Access = protected)
        function [data, details] = runOnProblem(obj, problem)
            % Run iterative methods on PROBLEM and report convergence
            % results.
            
            % Initializations and allocations
            level     = amg.setup.Level.newFinestLevel(problem.A, problem.b, obj.relaxFactory);
            
            % Generate TVs
            level.x         = level.relaxedTestVectors(5, 5);
            
            % Compute connections and generate output
            C               = obj.connectionEstimator.connectionMatrix(level);
            data            = numel(find(C))/problem.size;
            details.C       = C;
        end
    end
end
