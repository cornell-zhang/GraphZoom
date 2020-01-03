classdef (Sealed) RunnerMethod < lin.runner.AbstractRunnerProblem
    %RUNNERMETHOD Run a single iterative method and compute
    %convergence index.
    %   This class runs a single iterative method and computes some index,
    %   e.g. ACF.
    %
    %   See also: RUNNER, ITERATIVEMETHOD.
    
    %=========================== PROPERTIES ==============================
    properties (Constant, GetAccess = private)
        logger          = core.logging.Logger.getInstance('amg.runner.RunnerMethod')
    end
    
    properties (GetAccess = private, SetAccess = private)
        label           % method label
        target          % IterativeMethod factory
        resultComputer  % Computes ACF or some other statistics for each iterative method
        options         % Holds options specific to this object
    end
    
    %======================== CONSTRUCTORS ============================
    methods
        function obj = RunnerMethod(resultComputer, problemType, label, target, varargin)
            % Constructor.
            obj = obj@lin.runner.AbstractRunnerProblem(problemType, varargin);
            obj.resultComputer  = resultComputer;
            obj.label           = label;
            obj.target          = target;
        end
    end
    
    %======================== IMPL: Runner ===============================
    methods
        function fieldNames = fieldNames(obj)
            % Return a cell array of method labels. The elements of the
            % data array returned from run() correspond to these labels.
            fieldNames = {obj.label};
        end
    end
    
    %======================== Impl: RunnerProblem ========================
    methods (Access = protected)
        function [data, details] = runOnProblem(obj, problem)
            % Run iterative methods on PROBLEM and report convergence
            % results.

            methodInstance  = obj.target.newInstance(problem);
            [data, details] = obj.resultComputer.run(problem, methodInstance);
            % Save results
            details.label   = obj.label;
        end
    end
end
