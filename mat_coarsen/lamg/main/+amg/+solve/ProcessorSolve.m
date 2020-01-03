classdef (Sealed, Hidden) ProcessorSolve < amg.level.Processor & amg.api.HasOptions
    %PROCESSORSOLVE A solve cycle processor.
    %   This class executes the business logic of a multilevel LAMG
    %   solution cycle for the linear problem Ax=b.
    %
    %   See also: CYCLE, PROCESSOR.
    
    %======================== MEMBERS =================================
    properties (Constant, GetAccess = private)
        logger = core.logging.Logger.getInstance('amg.solve.ProcessorSolve')
        COARSEST_ERROR_REDUCTION_TOL = 1e-5
    end
    
    properties (GetAccess = private, SetAccess = private)
        setup               % Contains list of levels (1=finest, end=coarsest) and default cycle parameters
        finest              % Finest level

        b                   % Right-hand-side vector/matrix at all levels
        numB                % size(RHS,2)
        bStage              % Cell array of intermediate RHSs at elimination stages
        
        x                   % Solution at all levels
        r                   % Corresponding residual at all levels
        Tx                  % Restricted fine-level solution (for FAS)
        
        history             % Iterate history at all levels
        history_r           % Corresponding residuals
        latest              % A periodic pointer to the column index of history holding the latest iterate, at all levels
        numActive           % #active iterates in history at all levels
        historySize         % Allocation size of history at all levels
        
        % Coarsest solver fields
        useDirectSolver     % Use direct solver at coarsest level
%        AL                  % Coarsest-level matrix, computed once and then cached
        LL                  % L-factor of LU factorization of coarsest-level matrix
        UL                  % U-factor of LU factorization of coarsest-level matrix
        nL                  % #coarsest level nodes
        
        % Cached properties, for speed
        nuPre               % #pre relaxation sweeps at all levels
        nuPost              % #pre relaxation sweeps at all levels
        n                   % #nodes at all levels
        isAboveElimination  % Is level above elimination or not (flag array)
        doMinRes            % Use MINRES or not
        level               % Setup level hierarchy
    end
    
    %======================== CONSTRUCTORS ============================
    methods
        function obj = ProcessorSolve(setup, finest, numLevels, b, options)
            % Create a cycle executor with a level hierarchy specified by
            % SETUP and specific options OPTIONS.
            obj             = obj@amg.api.HasOptions(options);
            obj.setup       = setup;
            obj.finest      = finest;
            L               = min(setup.numLevels, finest+numLevels-1);
            
            % Set cached fields
            obj.level   = obj.setup.level;
            obj.nuPre   = obj.setup.nuPre;
            obj.nuPost  = obj.setup.nuPost;
            obj.doMinRes  = obj.options.minRes;
            obj.isAboveElimination = zeros(L, 1);
            for l = finest:L
                obj.isAboveElimination(l) = obj.setup.isAboveElimination(l);
            end

            % Initialize RHS arrays
            obj.b           = cell(L, 1);
            obj.bStage      = cell(L, 1);
            obj.b{finest}   = b;
            obj.numB        = size(b,2);
            
            % Allocate solution arrays
            obj.x           = cell(L, 1);
            obj.r           = cell(L, 1);
            obj.Tx          = cell(L, 1); % For FAS
            obj.history     = cell(L, 1);
            obj.history_r   = cell(L, 1);
            obj.historySize = zeros(L, 1);
            N               = obj.options.combinedIterates;
            for l = finest:L
                obj.n{l}            = setup.level{l}.g.numNodes;
                obj.history{l}      = zeros(obj.n{l}, N);
                obj.history_r{l}    = zeros(obj.n{l}, N);
                obj.historySize(l)  = N;
            end
            obj.latest      = zeros(L, 1); % Initial latest iterate = 0, will rotate through the values 1..N hereafter
            obj.numActive   = zeros(L, 1);
            
            % Initialize coarsest-level matrix problem
            fineLevel = obj.level{L};
            obj.nL  = obj.n{L};
            obj.useDirectSolver = (obj.options.cycleDirectSolver && (obj.nL <= obj.options.maxDirectSolverSize));
            if (obj.useDirectSolver)
                % Append rows & cols to eliminate zero modes
                AL = obj.initAugmentedProblem(fineLevel);
                % Factorize only once to save time
                [obj.LL, obj.UL] = lu(AL);
            end
        end
    end
    
    %======================== IMPL: Processor =========================
    methods
        function initialize(obj, l, dummy1, x, r) %#ok
            % Run at the beginning of a cycle at the finest level L.
            
            % Print a header line for cycle debugging printouts.
            if (obj.logger.debugEnabled && (obj.options.logLevel >= 2))
                obj.logger.debug('%-5s %-25s %-13s %-13s\n', ...
                    'LEVEL', 'ACTION', 'RES-NORM', 'L2-NORM');
            end
            obj.x{l} = x;
            obj.r{l} = r;
            obj.saveIterate(l, x, r);
        end
        
        function coarsestProcess(obj, l)
            % Run coarsest-level solver.
            fineLevel = obj.level{l};
            M = size(obj.b{l},2);
%             if (fineLevel.zeroMatrix)
%                 obj.x{l} = zeros(obj.n{l}, M);
%             elseif
            if (obj.useDirectSolver)
                % Two-level solver or direct solver requested, and it is
                % possible to directly solve ==> directly solve augmented
                % coarsest problem
                numComponents = 1;
                bL        = [obj.b{l}; zeros(numComponents, M)];
                %xL       = obj.AL\bL;
                % Use pre-computed LU factorization
                d         = obj.LL\bL;
                xL        = obj.UL\d;
                xL        = xL(1:obj.nL);
                obj.x{l}  = xL;
                obj.r{l}  = obj.b{l} - fineLevel.A*xL;
            elseif (l == 1)
                % One-level solver = single relaxation sweep
                [obj.x{l}, obj.r{l}] = obj.level{l}.relax(obj.x{l}, obj.r{l}, obj.b{l}, 1);
            else
                % Reduce coarsest problem residual by several orders of
                % magnitude with relaxation sweeps. Should be accurate
                % enough for any practical purposes.
                [obj.x{l}, obj.r{l}] = obj.relax(l, obj.options.cycleMaxCoarsestSweeps, obj.x{l}, obj.r{l}, amg.solve.ProcessorSolve.COARSEST_ERROR_REDUCTION_TOL, true);
            end
            %obj.printState(l, 'Direct solver');
        end
        
        function preProcess(obj, l)
            % Pre-relaxation and restriction to coarse level.
            
            % Alias fields to local variables - seems faster in MATLAB
            c           = l+1;
            fineLevel   = obj.level{l};
            coarseLevel = obj.level{c};
            xf          = obj.x{l};
            rf          = obj.r{l};
            bf          = obj.b{l};
            
            %obj.printState(l, 'Initial');
            
            %--- Pre-relaxation ---
            [xf, rf] = fineLevel.relax(xf, rf, bf, obj.nuPre(l));
            % Save back in state variables
            obj.x{l} = xf;
            obj.r{l} = rf;
            %obj.printState(l, sprintf('Pre-relax (%d)', obj.setup.nuPre(l)));
            
            %--- Coarse-level correction ---
            
            if (coarseLevel.isElimination)
                % Elimination level
                % Full eliminated solution
                [bc, obj.bStage{c}] = coarseLevel.restrict(bf);
                obj.b{c} = bc;
                % Initial guess for full coarse grid equations.
                % Identical to starting from xc=0 in CS
                obj.x{c} = coarseLevel.coarseType(xf);
                obj.r{c} = bc;
            else
                % AGG level
                switch (obj.options.cycleType)
                    case {'cs'}
                        % Correction scheme
                        bc       = coarseLevel.restrict(rf);
                        obj.b{c} = bc;
                        % Coarse level initial guess
                        obj.x{c} = zeros(obj.n{c}, obj.numB);
                        obj.r{c} = bc;
                    case {'fas'}
                        % Full approximation scheme
                        r           = bf - fineLevel.A*xf; %#ok
                        TX          = coarseLevel.restrict(xf);
                        obj.Tx{c}   = TX; % Reuse in the correction step
                        obj.b{c}    = coarseLevel.restrict(r) + coarseLevel.A*TX; %#ok
                        %sum(obj.b{c}) % FAS numerically unstable -- does
                        %not preserve RHS 0-row sums?
                        % Coarse level initial guess
                        % TODO: replace by dynamic residual implementation
                        obj.x{c}    = TX;
                        obj.r{c}    = obj.b{c} - coarseLevel.A*TX;
                    otherwise,
                        error('MATLAB:ProcessorSolve:preProcess', 'Unsupported cycle type ''%s''', obj.options.cycleType)
                end
                
                % Non-adaptive RHS energy correction strategy
                mu = coarseLevel.rhsMu;
                if (~isempty(mu))
                    obj.b{c} = mu .* obj.b{c};
                end
            end
            
            % Clear coarse-level iterate history
            obj.clearHistory(c);
%             if (l > obj.finest)
%                 obj.clearHistory(l);
%             end
        end
        
        function postProcess(obj, l)
            % Interpolate coarse-level correction and add it to x.
            
            % Alias fields to local variables - seems faster in MATLAB
            c           = l+1;
            fineLevel   = obj.level{l};
            coarseLevel = obj.level{c};
            xf          = obj.x{l};
            rf          = obj.r{l};
            bf          = obj.b{l};
            xc          = obj.x{c};
            rc          = obj.r{c};
            
            % Adaptive energy correction  at the coarse level via MINRES on
            % all post-relaxed iterates
            if (obj.doMinRes && ~obj.isAboveElimination(c))
                [xc, rc] = obj.minRes(c, xc, rc);
                obj.x{c} = xc;
                obj.r{c} = rc;
                %obj.printState(c, sprintf('min-res (%d)', obj.numActive(c)));
            end
            
            % Save previous pre-relaxed iterate at this level
            if (l > obj.finest)
                obj.saveIterate(l, xf, rf);
            end
            
            %--- Apply coarse grid correction to fine-level solution ---
            if (coarseLevel.isElimination)
                % Elimination level: full eliminated solution
                xf = coarseLevel.interpolate(xc, obj.bStage{c});
                rf = bf - fineLevel.A*xf;
            else
                % AGG level
                switch (obj.options.cycleType)
                    case {'cs'}
                        % Correction scheme
                        % Since we anyway need to recompute residual,
                        % recomputing it from scratch must be more stable
                        % instead of the dynamic residual approach
                        xf  = xf + coarseLevel.interpolate(xc);
                        rf  = bf - fineLevel.A*xf;
                        %rf = rf - fineLevel.A*e;
                    case {'fas'}
                        % Full approximation scheme
                        xf = xf + coarseLevel.interpolate(xc - obj.Tx{c});
                        % TODO: replace by dynamic residual implementation
                        rf = bf - fineLevel.A*xf;
                    otherwise,
                        error('MATLAB:ProcessorSolve:preProcess', 'Unsupported cycle type ''%s''', obj.options.cycleType)
                end
            end
            obj.x{l} = xf; % Debugging, remove when done
            obj.r{l} = rf; % Debugging, remove when done
            %obj.printState(l, 'Coarse-grid correction');
            
            %--- Post-relaxation ---
            [xf, rf] = fineLevel.relax(xf, rf, bf, obj.nuPost(l));
            % Save back in state variables
            obj.x{l} = xf;
            obj.r{l} = rf;
            %obj.printState(l, sprintf('Post-relax (%d)', obj.setup.nuPost(l)));
        end
        
        function postCycle(obj, l)
            % Execute at the finest level L at the end of the cycle.
            
            % Recombine iterates
            if (obj.doMinRes && ~obj.setup.isAboveElimination(l))
                %                if (obj.logger.debugEnabled)
                %                     obj.plotMinResQuality(l, obj.x{l},
                %                     obj.history{l}(:,end)-obj.x{l});
                %                     aaa=0; %#ok
                % end
                [obj.x{l}, obj.r{l}] = obj.minRes(l, obj.x{l}, obj.r{l});
                %obj.printState(l, sprintf('min-res (%d)', obj.numActive(l)));
            end
            
            % Remove zero modes
            obj.x{l} = removeZeroModes(obj.x{l}, []);
            %obj.printState(l, 'Removed 0-modes');
        end
        
        function [x, r] = result(obj, l)
            % Return the solution at level l.
            x = obj.x{l};
            r = obj.r{l};
        end
    end
    
    %======================== PRIVATE METHODS =========================
    methods (Access = private)
        function [x, r] = relax(obj, l, nu, x, r, stoppingResidualReduction, checkConvergence)
            % Perform NU relaxation sweeps on X at level LEVEL. If
            % PRINTEVERYSWEEP is true, generates debugging printouts after
            % every sweep; otherwise, only after the last sweep.
            %lev             = obj.level{l};
            bl              = obj.b{l};
            %rNormInitial    = lpnorm(obj.b{l} - lev.A*x);
            rNormInitial    = lpnorm(r);
            frequency       = 10;
            rThreshold      = max(1e-13, stoppingResidualReduction*(rNormInitial+eps));
            fineLevel       = obj.level{l};
            for i = 1:ceil(nu/frequency)
                [x, r] = fineLevel.relax(x, r, bl, frequency);
                if (checkConvergence)
                    % Break if residual norm is below a threshold or when
                    % we reach a steady state of x (even if the residual is
                    % non-zero; this precludes coarse-level incompatibility
                    % in periodic problems).
                    %rNorm = lpnorm(bl - lev.A*x);
                    rNorm = lpnorm(r);
                    if (rNorm < rThreshold)
                        break;
                    end
                end
            end
        end
        
        function A = initAugmentedProblem(obj, level) %#ok<MANU>
            % Append rows & cols to eliminate zero modes and return the
            % augmented A and b of the A*x=b problem at level LEVEL.
            Y = level.componentSpan;
            M = size(Y,2);
            A = [[level.A Y]; [Y' sparse(M,M)]];
        end
        
        function clearHistory(obj, l)
            % Clear the iterate history at level L.
            obj.latest(l) = 0;
            obj.numActive(l) = 0;
            %obj.printState(l, 'Clearing history');
        end
        
        function saveIterate(obj, l, x, r)
            % Save the iterate X in the level-L history.
            
            %N = size(obj.history{l}.x, 2);
            N = obj.historySize(l);
            if (N == 0)
                % Recombination is turned off
                return;
            end
            
            % Update latest pointer i
            i = obj.latest(l);
            i = i+1;
            if (i > N)
                i = 1;
            end
            obj.latest(l) = i;
            
            % Update #active iterates
            if (obj.numActive(l) < N)
                obj.numActive(l) = obj.numActive(l)+1;
            end
            
            % Update history array
            obj.history  {l}(:,i) = x;
            obj.history_r{l}(:,i) = r;
            %obj.printState(l, sprintf('Save x to #%d, active %d', i, obj.numActive(l)));
        end
        
        function [x, r] = minRes(obj, l, x, r)
            % Recombine the columns xi of the iterate history X with x to
            % y=x + sum_{i=1}^{N-1} alphai*(xi-x); alpha is chosen so that
            % y's L2 residual norm |b-A*y|_2 is minimized.
            %
            % This is only applied above aggregation levels, never above
            % elimination levels (no point).
            
            if (obj.numActive(l) > 0)
                N       = obj.numActive(l);
                X       = obj.history  {l}(:,1:N);
                R       = obj.history_r{l}(:,1:N);
                %w       = obj.setup.level{l}.rWeight;
                %A       = obj.level{l}.A;
                %E       = X-repmat(x, 1, N);
                cols    = ones(N,1);
                E       = X - x(:,cols);

                %E = repmat(obj.b{l}, 1, N) - A*X; % Leads to worse ACF
                % TODO: (optimization) save the need to calculate A here by
                % saving residuals (or even just AE and r) from the
                % previous iteration and updating them here
                %AE      = A*E;
                %r       = obj.b{l}-A*x;
                AE      = r(:,cols) - R;
                
                % Minimize |b-A*y|_2
                %                 if (rank(AE) < size(AE,2))
                %                     % Rank deficient, skip min-res. We're
                %                     probably close to % the exact
                %                     solution and suffering from
                %                     round-off.
                %                 else
                alpha   = AE\r;
                %                 if (l == obj.setup.numLevels)
                %                     alpha   = AE\r;
                %                 else
                %                     PT      = obj.setup.level{l+1}.R;
                %                     alpha   = (PT*AE)\(PT*r);
                %                 end
                %alpha = (w(:,cols).*AE)\(w.*r);
                
                % Minimize QuadForm(b-A*y). Adds more work but doesn't seem
                % to significantly improve convergence. Update: for g =
                    % Problems.laplacianGraphFromTestInstance('lap/ml/uf/GHS_indef/dtoc/level-2/level-7');
                    % Residual MINSRES 2-level ACF = 0.4, energy MINSRES
                    % ACF =
                    %                ET      = E'; alpha   =
                    %                (ET*AE)\(ET*r);
                    
                    x = x + E*alpha;
                    r = r - AE*alpha;
                    %                 if (obj.logger.debugEnabled &&
                    %                 (obj.options.logLevel >= 2) && (l <=
                    %                 obj.finest+2))
                    %                     obj.logger.debug('%-5d %-25s\n',
                    %                     l, 'alpha'); disp(alpha);
                    %                 end
%                end
            end
        end
        
        function printState(obj, l, action)
            % A debugging printout of the error norm at level L after a
            % certain action has been applied. The work per finest-level
            % relaxation sweep is also printed.
            
            % accessing logger multiple times is slow in big runs
            X = obj.x{l};
            %if (obj.logger.debugEnabled && (obj.options.logLevel >= 2) && (l <= obj.finest+2))
            if (obj.logger.debugEnabled && (obj.options.logLevel >= 2))
                obj.logger.debug('%-5d %-25s %-13.3e (%-13.3e) %-13.3e\n', l, action, ...
                    lpnorm(obj.r{l}), ...
                    lpnorm(obj.b{l}-obj.level{l}.A*X), ...
                    lpnorm(X));
            end
        end
        
        function plotMinResQuality(obj, l, x, E)
            A       = obj.level{l}.A;
            b       = obj.b{l}; %#ok
            r       = b-A*x; %#ok
            AE      = A*E;
            ET      = E';
            ar      = AE\r; %#ok
            ae      = (ET*AE)\(ET*r);%#ok
            
            E   = E - mean(E);
            a   = linspace(0, 2*ae, 30);
            x0  = A\b;  %#ok
            x0  = x0-mean(x0);
            res = zeros(numel(a),1);
            err = zeros(numel(a),1);
            energy = zeros(numel(a),1);
            for i = 1:numel(a),
                y = x + a(i)*E; % Corrected x
                res(i) = lpnorm(b-A*y);%#ok
                e = x0-y;
                err(i) = lpnorm(e-mean(e));
                energy(i) = 0.5*y'*A*y - y'*b; %#ok
            end
            res = (res - min(res))/(max(res) - min(res)) * (max(err)-min(err)) + min(err);
            energy = (energy - min(energy))/(max(energy) - min(energy)) * (max(err)-min(err)) + min(err);
            
            clf;
            figure(1);
            title(sprintf('Iterate Recombination: Level %d', l));
            subplot(2,1,1);
            nodes = 1:obj.level{l}.size;
            plot(nodes, x0-x-mean(x0-x), 'r', nodes, ar*E, 'b', nodes, ae*E, 'g');
            legend('True Error', '\alpha*(x-x_K) Residual', '\alpha*(x-x_K) Energy', ...
                'Location', 'NorthEast');
            
            subplot(2,1,2);
            plot(a, err, 'rx-',a, res, 'bx-', a, energy, 'gx-');
            xlabel('Recombination Coefficient \alpha');
            legend('Error Norm', 'Residual Norm (Scaled)', 'Energy Norm (Scaled)',...
                'Location', 'North');
            hold on; 
            aBest = a(argmin(err));
            e = x0-(x + aBest*E);
            plot(aBest, lpnorm(e-mean(e)), 'r.', 'MarkerSize', 25);
            e = x0-(x + ae*E);
            plot(ae, lpnorm(e-mean(e)), 'g.', 'MarkerSize', 25);
            e = x0-(x + ar*E);
            plot(ar, lpnorm(e-mean(e)), 'b.', 'MarkerSize', 25);
            shg;
        end
    end
end