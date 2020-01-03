classdef (Sealed) RunnerMethodComparison < lin.runner.AbstractRunnerProblem
    %RUNNERACF Compare iterative methods in a batch run.
    %   This class runs multiple iterative methods and computes their
    %   respective Asymptotic Convergence Factors (ACFs), or some other
    %   statistics.
    %
    %   See also: RUNNER, ITERATIVEMETHOD.
    
    %=========================== PROPERTIES ==============================
    properties (Constant, GetAccess = private)
        logger          = core.logging.Logger.getInstance('lin.runner.RunnerMethodComparison')
        %        RELAX_FACTORY   = amg.relax.RelaxFactory;
    end
    
    properties (GetAccess = private, SetAccess = private)
        targets         % List of (method label, IterativeMethod instance)
        resultComputer  % Computes ACF or some other statistics for each iterative method
        options         % Holds options specific to this object 
    end
    
    %======================== CONSTRUCTORS ============================
    methods
        function obj = RunnerMethodComparison(problemFactory, resultComputer, varargin)
            % Constructor.
            obj = obj@lin.runner.AbstractRunnerProblem(problemFactory);
            obj.resultComputer = resultComputer;
            
            % Parse input arguments specific to this class
            obj.options = lin.runner.RunnerMethodComparison.parseArgs(varargin{:});
        end
    end
    
    %======================== IMPL: Runner ===============================
    methods
        function fieldNames = fieldNames(obj)
            % Return a cell array of method labels. The elements of the
            % data array returned from run() correspond to these labels.
            numMethods = numel(obj.targets);
            fieldNames = cell(obj.dataSize, 1);
            for i = 1:numMethods
                fieldNames{i} = obj.targets{i}.label;
            end
            if ((numMethods > 1) && obj.options.computeBest)
                % Overall stats: best ACF
                fieldNames{numMethods+1} = 'best';
            end
        end
    end
    
    %=========================== METHODS =================================
    methods
        function addMethod(obj, label, iterativeMethodFactory)
            % Add an iterative method to the methods run by this object
            % with label LABEL. The iterative method depends on the current
            % problem, so we instead add iterativeMethodFactory, which
            % produces an iterativeMethod instance per problem.
            methodStruct.label      = label;
            methodStruct.factory    = iterativeMethodFactory;
            obj.targets = [obj.targets {methodStruct}];
        end
        
        function addMethods(obj, labels, iterativeMethodFactories)
            % Add multiple methods.
            for i = 1:numel(labels)
                obj.addMethod(labels{i}, iterativeMethodFactories{i});
            end
        end
    end
    
    %======================== Impl: RunnerProblem ========================
    methods (Static, Access = private)
        function args = parseArgs(varargin)
            % Parse input arguments.
            p                   = inputParser;
            p.FunctionName      = 'RunnerMethodComparison';
            p.KeepUnmatched     = true;
            p.StructExpand      = true;
            
            % If true, adds a data column with the best method of all
            % methods compared. Treated as false regardless the input value
            % if only one method is run
            p.addParamValue('computeBest', true, @islogical);
            
            p.parse(varargin{:});
            args = p.Results;
        end
    end
    
    methods (Access = private)
        function sz = dataSize(obj)
            % Return the size of the data array to allocate
            numMethods  = numel(obj.targets);
            sz          =  numMethods;
            if ((numMethods > 1) && obj.options.computeBest)
                sz = sz+1; % Overall stats: best ACF
            end
        end
    end
    
    methods (Access = protected)
        function [data, details] = runOnProblem(obj, problem)
            % Run iterative methods on PROBLEM and report convergence
            % results.
            
            numMethods  = numel(obj.targets);
            data        = zeros(1, obj.dataSize);
            details     = cell(numMethods, 1);
            
            for i = 1:numMethods
                % Construct method for this problem
                methodStruct    = obj.targets{i};
                if (obj.logger.debugEnabled)
                    obj.logger.debug('Running method %s\n', methodStruct.label);
                end
                methodInstance  = methodStruct.factory.newInstance(problem);
                [methodData, methodDetails] = obj.resultComputer.run(problem, methodInstance);
                % Save results
                methodDetails.label     = methodStruct.label;
                data(:,i)               = methodData;
                details{i}              = methodDetails;
            end
            
            if ((numMethods > 1) && obj.options.computeBest)
                % Overall stats: best ACF
                data(numMethods+1) = min(data(1:numMethods));
            end
        end
    end
end
