classdef (Sealed) AcfComputer < lin.api.IterativeIndexComputer
    %ACFCOMPUTER Compute the ACF of an iterative methods.
    %   This class runs an iterative methods and estimates its Asymptotic
    %   Convergence Factor (ACF).
    %
    %   See also: RUNNER, ITERATIVEMETHOD.
    
    %=========================== PROPERTIES ==============================
    properties (Constant, GetAccess = private)
        logger = core.logging.Logger.getInstance('lin.api.AcfComputer')
    end
    
    %======================== CONSTRUCTORS ============================
    methods
        function obj = AcfComputer(varargin)
            % Initialize a relaxation factory. OPTIONS contains
            % construction arguments for instances returned from
            % newInstance().
            obj = obj@lin.api.IterativeIndexComputer(varargin{:});
        end
    end
    
    %======================== IMPL: IterativeIndexComputer ============
    methods (Access = protected)
        function [acf, convFactorHistory, x, stats] = runIterations(obj, problem, iterativeMethod, x, r)
            % Run a sequence of iterations of ITERATIVEMETHOD at the finest
            % problem PROBLEM and return the convergence history vector
            % CONVFACTORYHISTORY and the asymptotic vector X.
            
            % Initialization + initial guess. Must substract the mean from
            % the initial guess and all iterates if the L2 error norm is
            % used, so that we can converge to 0. Note that a stationary
            % iterative method *may* change the mean.
            %flops(0);       % Reset flop count
            x                   = obj.removeZeroModes(x); % Does not change r
            eNew                = obj.options.errorNorm(problem, x, r, [], []); % Third arg is xold that does not yet exist; using 0 even though it's arbitrary
			relative_norm = obj.options.relativeNorm(problem, x, []); % norm(Ax-b)/norm(b)
            k                   = obj.options.sampleSize;
            %N                   = obj.options.combinedIterates; N = 0;
            oneClosednessTol    = 1e-8;
            %iterateHistory      = [];  % Holds the last k iterates, k=options.combinedIterates
            %memory
            lastIterationsStall = false;
            
            % Run method to asymptote
            eFinal              = max(obj.options.finalErrorNorm, eNew*obj.options.errorReductionTol);
            convFactorHistory   = zeros(obj.options.maxIterations, 1);
            stats = struct();
            stats.errorNormHistory = zeros(obj.options.maxIterations+1, 1);
            stats.errorNormHistory(1) = eNew;
            if (obj.options.logLevel >= 1)
                tStartAll = tic;
                obj.logger.debug('Initial     e=%.3e\n', eNew);
            end
            
            %            h = [];
            for iteration = 1:obj.options.maxIterations
                % Print debugging lines only for the first few cycles
                if (obj.logger.debugEnabled && (obj.options.logLevel >= 1))
                    tStart = tic;
                end
                if (obj.options.logLevel >= 2)
                    obj.logger.debug('##################### ITERATION #%d #####################\n',...
                        iteration);
                end
                
                % Update iteration history
                eOld = eNew;
                xOld = x;
                rOld = r;
                %                 if (isa(x, 'amg.eig.Eigenpair'))
                %                     h = [h amg.eig.Eigenpair(x.x,
                %                     x.lam)];
                %                 end if (N > 1)
                %                     if (iteration < N)
                %                         iterateHistory = [iterateHistory
                %                         x]; %#ok - N should be small
                %                     else
                %                         iterateHistory =
                %                         [iterateHistory(:,2:end) x];
                %                     end
                %                end
                for unitIteration = 1:obj.options.numIters
                    [x, r]  = iterativeMethod.run(x,r);
                    x       = obj.removeZeroModes(x);
                end
                %                x     = obj.recombineIterates(problem, x,
                %                iterateHistory);
                eNew  = obj.options.errorNorm(problem, x, r, xOld, rOld);
				relative_norm = obj.options.relativeNorm(problem, x, []);
                stats.errorNormHistory(iteration+1) = eNew;
                if (eOld == 0) && (eNew == 0)
                    convFactor = 0;
                else
                    convFactor  = (eNew/eOld)^(1/obj.options.numIters);
                end
                convFactorHistory(iteration) = convFactor;
                
                % Stop when either round-off level or reached steady state
                % is reached
                if (iteration > k)
                    R       = convFactorHistory(iteration-k+1:iteration);
                    ratio   = mean(abs(diff(R)) ./ R(2:end)) / max(oneClosednessTol, mean(abs(1-R)));
                    % Reached round-off or method slowness
                    lastIterationsStall = (min(R) > obj.options.acfStallValue);
                else
                    lastIterationsStall = false;
                end
                stop = ((convFactor < 1e-15) || (eNew < eFinal) || ...
                    ((iteration > k) && (ratio < obj.options.steadyStateTol)) || ...
                    lastIterationsStall);

				stop = (relative_norm < 1e-4);
				%fprintf('norm(Ax-b)/norm(b) = %f\n', relative_norm);
                
                if (obj.logger.debugEnabled && (obj.options.logLevel >= 1))
                    t = toc(tStart);
                    obj.logger.debug('Iter %#4d   e=%.3e  conv=%s   time=%.2g [sec]\n', ...
                        iteration, eNew, formatAcf(convFactor), t);
                elseif ((obj.logger.debugEnabled) && (...
                        stop || ...
                        (iteration < 10) || ...
                        ((iteration < 100) && (mod(iteration,10) == 0)) || ...
                        ((iteration < 1000) && (mod(iteration,100) == 0)) || ...
                        ((iteration < 10000) && (mod(iteration,1000) == 0)) ...
                        ))
                    obj.logger.debug('Iter %#4d   e=%.3e  conv=%s\n', ...
                        iteration, eNew, formatAcf(convFactor));
                end
                if (stop)
                    break;
                end
            end
            
            % Trim last iterations if reached round off
            if (lastIterationsStall)
                iteration = max(k,iteration-k+1);
            end
            %fprintf('Iter = %d\n', iteration);
            % Trim stats arrays
            stats.convFactorHistory = convFactorHistory(1:iteration);
            stats.errorNormHistory = stats.errorNormHistory(1:iteration+1);
            
            % Clean up large arrays
            %clear zeroModes; work = flops;
            
            if (obj.logger.debugEnabled && (obj.options.logLevel >= 1))
                tAll = toc(tStartAll);
                obj.logger.debug('Total time: %.2g [sec]\n', tAll);
            end
            
            % Estimate ACF
            acf = obj.acf(stats);
        end
    end
    
    %======================== IMPL: IterativeIndexComputer ============
    methods (Access = private)
        function x = removeZeroModes(obj, x)
            % Remove x's zero modes of subtract the mean depending on input
            % options.
            switch (obj.options.removeZeroModes)
                case 'mean'
                    x = removeZeroModes(x, []);
                    return;
                case 'none'
                    return;
            end
        end
        
        function rho = acf(obj, stats)
            % Estimate the asmptotic convergence factor.
            switch (obj.options.acfEstimate)
                case 'smooth-filter'
                    % Good for fixed-point iterations (relaxation, normal
                    % MG cycles)
                    rho = acf(stats.convFactorHistory);
                    return;
                case 'reduction-per-iter'
                    % Good for jumpy convergence per iteration such as
                    % CG/adaptive energy correction
                    rho = reductionPerIter(stats.errorNormHistory,2);
                    return;
            end
        end
    end
end
