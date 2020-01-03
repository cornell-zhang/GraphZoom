classdef (Sealed) TvFactory < handle
    %PROBLEMFACTORY A factory of test vector generation objects.
    %   This class produces Problem objects instances for a graph G based
    %   on input options. It internally delegates to package-private
    %   ProblemSetup builders.
    %
    %   See also: PROBLEM, PROBLEMSETUP.
    
   %=========================== PROPERTIES ==============================
    properties (Constant, GetAccess = private)
        logger = core.logging.Logger.getInstance('amg.tv.TvFactory')
        
        % Cached Delegates
        tvRandom        = amg.tv.TvInitialGuessRandom
        tvFourier       = amg.tv.TvInitialGuessFourier
        tvPolynomial    = amg.tv.TvInitialGuessPoly
        tvFromFine      = amg.tv.TvInitialGuessFromFine
    end
    
    %======================== METHODS =================================
    methods 
        function [x, r] = generateTvs(obj, level, initialGuess, K, nu, lda, kpower)
            % Generate K TVs using the initial guess type INITIALGUESS plus
            % nu relaxation sweeps.

            % Generate TV initial guesses, as many as there are at the next
            % finest-level
            %if (isempty(level.fineLevel) || isempty(level.fineLevel.x))
                Kfine = K;
            %else
            %    Kfine = size(level.fineLevel.x, 2);
            %end
            x = obj.tvInitialGuess(initialGuess).build(level, Kfine);
            r = -level.A*x;
            
            % AGG level: if a TV increment was requested, create more
            % random vectors. Then relax each vector nu times.
            if (level.isElimination || isempty(level.fineLevel))
                tvIncrement = 0;
            else
                tvIncrement = K - Kfine;
            end
            
            %if (~level.hasDisconnectedNodes) &&
            if (tvIncrement > 0)
                % Compute initial TV and the corresponding action
                tv  = obj.tvInitialGuess(initialGuess).build(level, tvIncrement);
                x   = [x tv];
                r   = [r -level.A*tv];
                if (obj.logger.debugEnabled)
                    obj.logger.debug('Adding %d TVs, #TVs = %d\n', ...
                        tvIncrement, size(x,2));
                end
            end
            [x, r] = level.tvRelax(x, r, nu, lda, kpower);
        end
        %x = x-repmat(mean(x,1),size(x,1),1);
    end
    
    %======================== PRIVATE METHODS =========================
    methods (Access = private)
        function x = tvInitialGuess(obj, initialGuess) %#ok<MANU>
            % Return a TV initial guess generator instance of type
            % INITIALGUESS. If INITIALGUESS = [], returns the default
            % generator.
            
            if (isempty(initialGuess))
                initialGuess = 'random'; % Default generator
            end
            
            switch (initialGuess)
                case 'random'
                    x = amg.tv.TvFactory.tvRandom;
                case 'poly'
                    % 1, x, x^2, ...
                    x = amg.tv.TvFactory.tvPoly;
                case 'fourier'
                    % 1, cos(x), cos(2*x),...
                    x = amg.tv.TvFactory.tvFourier;
                case 'current'
                    % x = T*xf
                    x = amg.tv.TvFactory.tvFromFine;
                otherwise
                    error('MATLAB:TvFactory:tvInitialGuess', 'Unknown TV initial guess type ''%s''', tvInitialGuess);
            end
        end
    end
end
