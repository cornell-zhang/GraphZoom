classdef (Sealed) RunnerRelaxAcfWof < lin.runner.AbstractRunnerProblem
    %RUNNERMETHOD Run a single iterative method and compute
    %convergence index.
    %   This class runs a single iterative method and computes some index,
    %   e.g. ACF.
    %
    %   See also: RUNNER, ITERATIVEMETHOD.
    
    %=========================== PROPERTIES ==============================
    properties (Constant, GetAccess = private)
        logger          = core.logging.Logger.getInstance('amg.util.RunnerRelaxAcfWof')
    end
    
    properties (GetAccess = private, SetAccess = private)
        target          % IterativeMethod factory
        acfComputer     % Computes relxation ACF
        wofComputer     % Computes relxation WOF
        options         % Holds options specific to this object
    end
    
    %======================== CONSTRUCTORS ============================
    methods
        function obj = RunnerRelaxAcfWof(problemFactory, target, varargin)
            % Constructor.
            obj = obj@lin.runner.AbstractRunnerProblem(problemFactory, varargin{:});
            obj.acfComputer     = lin.api.AcfComputer(varargin{:});
            obj.wofComputer     = amg.runner.WofComputer(varargin{:});
            obj.target          = target;
        end
    end
    
    %======================== IMPL: Runner ===============================
    methods
        function fieldNames = fieldNames(obj)
            % Return a cell array of method labels. The elements of the
            % data array returned from run() correspond to these labels.
            fieldNames = cell(obj.wofComputer.nu+1, 1);
            fieldNames{1} = 'ACF';
            for wofIteration = 1:obj.wofComputer.nu
                fieldNames{wofIteration+1} = sprintf('WOF-%d', wofIteration);
            end
        end
    end
    
    %======================== Impl: RunnerProblem ========================
    methods (Access = protected)
        function [data, details] = runOnProblem(obj, problem)
            % Run iterative methods on PROBLEM and report convergence
            % results.

            % Allocations
            methodInstance  = obj.target.newInstance(problem);
            data            = zeros(obj.wofComputer.nu+1, 1);
            
            % Compute ACF and stats
            [acf, details]  = obj.acfComputer.run(problem, methodInstance);
            data(1)         = acf;
            details.acf     = details;

            % Compute WOF and stats
            [wof, details]  = obj.wofComputer.run(problem, methodInstance);
            data(2:end)     = wof;
            details.wof     = details;
        end
    end
end
