classdef IterativeIndexComputer < amg.api.HasOptions
    %ITERATIVEINDEXCOMPUTER Compute some index of an iterative methods.
    %   This class runs an iterative method and estimates a certain index
    %   (e.g. ACF, WOF) of its convergence.
    %
    %   See also: RUNNER, ITERATIVEMETHOD.
    
    %=========================== PROPERTIES ==============================
    properties (Constant, GetAccess = private)
        myLogger = core.logging.Logger.getInstance('lin.api..IterativeIndexComputer')
    end
    
    %======================== CONSTRUCTORS ============================
    methods
        function obj = IterativeIndexComputer(varargin)
            % Initialize a relaxation factory. OPTIONS contains
            % construction arguments for instances returned from
            % newInstance().
            options = lin.api.IterativeIndexComputer.parseArgs(varargin{:});
            obj     = obj@amg.api.HasOptions(options);
        end
    end
    
    %======================== METHODS =================================
    methods
        function [index, details, x] = run(obj, problem, iterativeMethod, varargin)
            % Run the method iterativeMethod on the problem PROBLEM and
            % return convergence results.
            
            hom = ~isempty(problem.b); % Is problem homogeneous
            if (numel(varargin) >= 1)
                x0 = varargin{1};
            elseif (~isempty(obj.options.x0))
                x0 = obj.options.x0;
            else
                % Default initial guess: biased random[-1,1]
                %setRandomSeed(obj.options.randomSeed);
                setRandomSeed(1);
                if (hom)
                    % Non-homogeneous problem
                    numCols = size(problem.b, 2);
                else
                    % Homogeneous problem
                    numCols = 1;
                end
                x0 = randInRange(-obj.options.initialGuessNorm, obj.options.initialGuessNorm, problem.g.numNodes, numCols);
                x0 = x0.^2; % Introduce bias
            end
            
            % Compute initial residual
            if (hom)
                r0 = problem.b - problem.A*x0;
            else
                r0 = problem.A*x0;
            end

            [index, convFactorHistory, x, stats] = obj.runIterations(problem, iterativeMethod, x0, r0);
            if (obj.myLogger.debugEnabled)
                obj.myLogger.debug('Index estimate = %.3f\n', index);
            end
            
            % Save results
            details                     = struct();
            details.stats               = stats;
            details.convHistory         = convFactorHistory;
            details.index               = index;
            % The following require large storage
            if (strcmp(obj.options.output, 'full'))
                details.asymptoticVector  = x;
                details.iterativeMethod   = iterativeMethod;
                %details.work              = work;
            end
        end
    end
    
    %======================== PRIVATE METHODS =========================
    methods (Static, Access = private)
        function options = parseArgs(varargin)
            % Parse input options.
            p                   = inputParser;
            p.FunctionName      = 'IterativeIndexComputer';
            p.KeepUnmatched     = true;
            p.StructExpand      = true;
            
            p.addParamValue('x0', [], @isnumeric);
            p.addParamValue('maxIterations', 500, @isnumeric);
            p.addParamValue('steadyStateTol', 1e-2, @isnumeric);
            % Size of iteration sample averaged to compute the ACF estimate
            p.addParamValue('sampleSize', 10, @isPositiveIntegral);
            p.addParamValue('errorReductionTol', 1e-15, @isnumeric);
            p.addParamValue('finalErrorNorm', 1e-15, @isnumeric);
            p.addParamValue('initialGuessNorm', 1, @isnumeric);
            p.addParamValue('errorNorm', @errorNormL2, @(x)(isa(x, 'function_handle')));

			p.addParamValue('relativeNorm', @errorNormResidualRelative, @(x)(isa(x, 'function_handle')));
            % Number of iterates for iterate recombination
            p.addParamValue('combinedIterates', 1, @(x)(x >= 1));
            % Optional initial guess; will use random[-1,1] if empty
            %p.addParamValue('initialGuess', [], @(x)(isempty(x) ||
            %isvector(x)));
            % Determines iteration history printout format
            p.addParamValue('logLevel', 0, @isPositiveIntegral);
            
            % If specified, we add x*imaginaryPerturbation/n to the
            % iterate x after n iterations. Useful for multiple dominant
            % iteration eigenvectors that cause the convergence per
            % (raw) cycle to alternate between few values.
            %p.addParamValue('imaginaryPerturbation', 0, @(x)(x >= 0));
            
            % Number of iterations to count as one unit. Convergence per
            % iteration within a unit is reported as the ACF.
            p.addParamValue('numIters', 1, @(x)(x >= 1));
            
            % Remove zero modes (mean only or each component specified by
            % the problem.componentIndex cell array)
            p.addParamValue('removeZeroModes', 'mean', @(x)(any(strcmp(x,{'mean', 'all', 'none'}))));
            %p.addParamValue('componentIndex', {}, @iscell); % Can't be
            %specified here because it is problem-specific
            p.addParamValue('output', 'minimal', @(x)(any(strcmp(x,{'minimal', 'full'}))));
            p.addParamValue('acfEstimate', 'smooth-filter', @(x)(any(strcmp(x,{'smooth-filter', 'reduction-per-iter'}))));
            p.addParamValue('acfStallValue', 0.98, @(x)((x > 0) && (x <= 1)));
            
            p.parse(varargin{:});
            options = p.Results;
        end
    end
    
    methods (Abstract, Access = protected)
        [index, convFactorHistory, x, stats] = runIterations(obj, problem, iterativeMethod, x0)
        % Run a sequence of iterations of ITERATIVEMETHOD at the finest
        % problem PROBLEM, compute the iterative method index estimate
        % INDEX, and return the convergence history vector
        % CONVFACTORYHISTORY and the asymptotic vector X. X0 = optional
        % initial guess; will use random[-1,1] if empty.
    end
    
    methods (Sealed, Access = protected)
        function x = recombineIterates(obj, problem, x, iterateHistory)
            M = size(x,2);
            for i = 1:M
                x(:,i) = recombineIteratesSingleProblem(obj, problem, x(:,i), i, iterateHistory(:,i:M:end));
            end
        end
        
        function x = recombineIteratesSingleProblem(obj, problem, x, i, iterateHistory)
            % Recombine x and the iterates in iterateHistory to minimize
            % the L2 residual norm |A*x-b|_2.
            if (~isempty(iterateHistory))
                % y = x + sum_{i=1}^{N-1} alphai*(xi-x), alpha chosen so
                % that y's L2 residual norm is minimized
                [n, K]  = size(iterateHistory);
                E       = iterateHistory-repmat(x, 1, K);
                AE      = problem.A*E;
                k       = find(sqrt(sum(AE.^2,1)./n) < eps, 1);
                if (~isempty(k))
                    % An exact solution iterate exists, use it
                    x = iterateHistory(:,k);
                else
                    %alpha   = AE\(problem.b(:,i) - problem.A*x);
                    ET      = E';
                    alpha   = (ET*AE)\(ET*(problem.b(:,i) - problem.A*x));
                    x       = x + E*alpha;
                end
                if (obj.myLogger.debugEnabled && (obj.options.logLevel >= 2))
                    action = sprintf('min-res (%d iterates)', K+1);
                    obj.myLogger.debug('%-5d %-25s %-13.3e %-13.3e\n', 1, action, ...
                        lpnorm(problem.b(:,i) - problem.A*x), ...
                        lpnorm(x));
                end
            end
        end
    end
end
