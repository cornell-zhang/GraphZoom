classdef (Sealed) RunnerAggregator < lin.runner.AbstractRunnerProblem
    %RUNNERAGGREGATOR Test computing the coarse set of aggregates.
    %   This class creates a single Level from a Problem instance,
    %   generates TVs and aggregates nodes using an Aggregator.
    %
    %   See also: AGGREGATOR, RELAX.
    
    %=========================== PROPERTIES ==============================
    properties (Constant, GetAccess = private)
        logger     = core.logging.Logger.getInstance('amg.util.RunnerAggregator')
        TV_FACTORY = amg.tv.TvFactory
        LEVEL_FACTORY = amg.level.LevelFactory
    end
    
    properties (GetAccess = private, SetAccess = private)
        relaxFactory          % TV relaxation scheme (factory)
        tvInitialGuess          % Type of TV initial guess
        aggregator              % Aggregates nodes into a coarse set
    end
    
    %======================== CONSTRUCTORS ============================
    methods
        function obj = RunnerAggregator(varargin)
            % Constructor.
            obj                 = obj@lin.runner.AbstractRunnerProblem(@Problems.laplacianHomogeneous);
            obj.relaxFactory    = amg.relax.RelaxFactory('relaxType', 'gs');
            options             = amg.api.Options.fromStruct(amg.api.Options, varargin{:});
            obj.aggregator      = amg.coarse.Aggregator(options);
            obj.tvInitialGuess  = options.tvInitialGuess;
        end
    end
    
    %======================== IMPL: Runner ===============================
    methods
        function fieldNames = fieldNames(obj) %#ok<MANU>
            % Return a cell array of method labels. The elements of the
            % data array returned from run() correspond to these labels.
            fieldNames = cell(3, 1);
            fieldNames{1} = 'alpha';
            fieldNames{2} = 'beta';
            fieldNames{3} = 'HCR ACF';
        end
    end
    
    %======================== Impl: RunnerProblem ========================
    methods (Access = protected)
        function [data, details] = runOnProblem(obj, problem)
            % Run iterative methods on PROBLEM and report convergence
            % results.
            
            % Initializations and allocations
            level = RunnerAggregator.LEVEL_FACTORY.newInstance(...
                amg.level.LevelType.FINEST, ...
                1, amg.setup.CoarseningState.FINEST, ...
                obj.relaxFactory, 5, ...
                'A', problem.A, 'g', problem.g);
            level.x = RunnerAggregator.TV_FACTORY.generateTvs(level, 'random', 5, 5);
            
            % Create a coarse aggregate set
            result          = obj.aggregator.aggregate(level, 1.2);
            [dummy1, T, dummy2, data(1)] = result.optimalResult(); %#ok
            details.history = result;
            details.T       = T;
        end
    end
end
