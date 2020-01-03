classdef (Sealed, Hidden) RunnerSolver < lin.runner.AbstractRunnerProblem
    %RUNNERCYCLEACF Run a single linear solver on Ax=b.
    %   This class invokes a Solver object on a linear problem and outputs
    %   performance statistics.
    %
    %   See also: RUNNER, RUNNERSOLVERS, SOLVER.
    
    %=========================== PROPERTIES ==============================
    properties (Constant, GetAccess = private)
        logger          = core.logging.Logger.getInstance('lin.runner.RunnerSolver')
    end
    
    properties (GetAccess = private, SetAccess = public) % Injected dependencies
        solverContext       % Like a spring container shared by all solver runners
    end
    properties (GetAccess = private, SetAccess = private) % Injected dependencies
        name                % Solver name (unique identifier)
        solver              % managed Solver instance
        runOptions          % Run options
    end
    
    %======================== CONSTRUCTORS ===============================
    methods
        function obj = RunnerSolver(problemFactory, name, solver, varargin)
            % Construct a solver runner from input options.
            obj             = obj@lin.runner.AbstractRunnerProblem(problemFactory);
            obj.name        = name;
            obj.solver      = solver;
            if (numel(varargin) < 1)
                obj.runOptions = struct('dieOnException', true, 'clearWhenDone', false);
            else
                obj.runOptions = varargin{1};
            end
        end
    end
    
    %======================== IMPL: AbstractProblemRunner ================
    methods
        function fieldNames = fieldNames(obj)
            % Return a cell array of solver output fields.
            
            % TODO: add dynamic solver statistics
            fieldNames = [{'success', 'tSetup', 'tSolve'} obj.solver.detailsFieldNames()];
        end
    end
    
    methods (Access = protected)
        function [result, details] = runOnProblem(obj, problem)
            % Run the solver on PROBLEM and report results.
            
            % Set up solver (skip if setup already found in solver context)
            if (obj.runOptions.dieOnException)
                % Development mode - reveal true exception source
                [success, tSetup, tSolve, details] = obj.doRunOnProblem(problem);
            else
                % Production mode
                try
                    [success, tSetup, tSolve, details] = obj.doRunOnProblem(problem);
                catch e
                    % Error occurred
                    if (obj.logger.infoEnabled)
                        obj.logger.info('%s failed: %s\n', obj.name, e.message);
                    end
                    success = 0;
                end
            end
            
            % Prepare output struct
            if (~success)
                tSetup = -1;
                tSolve = -1;
            end
            details.success = success;
            details.tSetup  = tSetup;
            details.tSolve  = tSolve;
            result          = [];
            for f = obj.fieldNames()
                field = f{:};
                result = [result details.(field)]; %#ok
            end
        end
    end
    
    %======================== METHODS ====================================
    methods
        function tTotal = totalTime(obj, tSetup, tSolve)
            % Calculate standardized total time for solving a problem.
            % TODO: move to a reusable function that plotResultBundle()
            % can use.
            if (obj.solver.iterative)
                % Solving to 10 significant figures is considered a
                % "standard solve"
                tTotal = tSetup + 10*tSolve;
            else
                tTotal = tSetup + tSolve;
            end
        end
    end
    
    %======================== GET & SET ===============================
    methods
        function set.solverContext(obj, solverContext)
            % Register ourselves with a solver context.
            obj.solverContext = solverContext;
            solverContext.createSolverKey(obj.solver.contextKey); %#ok
        end
    end
    
    %======================== PRIVATE METHODS =========================
    methods (Access = private)        
        function [success, tSetup, tSolve, details] = doRunOnProblem(obj, problem)
            key     = obj.solver.contextKey;
            setup   = obj.solverContext.getData(key, 'setup');
            if (~isempty(key) && ~isempty(setup))
                tSetup = obj.solverContext.getData(key, 'tSetup');
            else
                if (obj.logger.debugEnabled)
                    obj.logger.debug('\n');
                    obj.logger.debug('==================================\n');
                    obj.logger.debug('%s: Setup Phase\n', obj.name);
                    obj.logger.debug('==================================\n');
                end
                tStart = tic;
                setup = obj.solver.setup('graph', problem.g);
                tSetup  = toc(tStart) / problem.g.numEdges;
                % Save setup in solver context so that subsequent
                % solvers of the same type can reuse it
                if (~isempty(key) && ~isempty(setup))
                    obj.solverContext.setData(key, 'setup', setup);
                    obj.solverContext.setData(key, 'tSetup', tSetup);
                end
            end
            
            % Solve problem
            if (obj.logger.debugEnabled)
                disp(setup);
                obj.logger.debug('\n');
                obj.logger.debug('==================================\n');
                obj.logger.debug('%s: Solve Phase\n', obj.name);
                obj.logger.debug('==================================\n');
            end
            tStart = tic;
            [dummy, success, errorHistory, details] = obj.solver.solve(setup, problem.b); %#ok
            tSolveTotal = toc(tStart);
            tSolve = normalizedSolveTime(tSolveTotal, errorHistory, obj.solver.iterative) / problem.g.numEdges;
            details.errorHistory = errorHistory;
            details.setup = setup;
            if (obj.runOptions.clearWhenDone)
                try
                    details.setup.clear();
                catch e  %#ok % method clear() is not supported by this solver, remove entire setup
                    clear details.setup;
                    details.setup = [];
                end
            end
        end
    end
end
