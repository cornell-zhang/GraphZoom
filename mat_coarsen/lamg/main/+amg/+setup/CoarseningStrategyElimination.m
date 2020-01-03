classdef (Hidden, Sealed) CoarseningStrategyElimination < amg.setup.CoarseningStrategy
    %CoarseningStrategyElimination Low-impact node elimination.
    %   This class builds an elimination level of 1- and 2- degree nodes
    %   that are independent of each other.
    %
    %   See also: COARSENINGSTRATEGY, MULTILEVELSETUP.
    
    %=========================== PROPERTIES ==============================
    properties (Constant, GetAccess = private)
        myLogger = core.logging.Logger.getInstance('amg.setup.CoarseningStrategyElimination')
    end
    
    %======================== CONSTRUCTORS ============================
    methods
        function obj = CoarseningStrategyElimination(options)
            % Initialize this object.
            obj = obj@amg.setup.CoarseningStrategy(options);
        end
    end
    
    %======================== IMPL: CoarseningStrategy ================
    methods (Access = protected)
        function [coarseLevel, hcr, beta, nu, details] = buildInternal(obj, target, problem, fineLevel)
            % Build and return the next-coarser level COARSELEVEL using the
            % strategy encapsulated in this object. FINELEVEL is the
            % coarsest level to date (one above LEVEL).
            
            % Find low-degree nodes
            A           = fineLevel.A;
            g           = fineLevel.g;
            degree      = g.degree;
            stageNum    = 0;
            n           = size(A,1);
            details     = struct('nnzFNodes', 0, 'timeCoarsening', 0, 'timeRelax', 0, 'isExactElimination', true);
            sz          = 5;
            stage       = cell(1,sz);

            % Filter small connections (will do defect correction with the
            % sparsified A containing only the strong connections)
            if (obj.options.eliminationStrongEdgesBased)
                numEdges    = fineLevel.g.numEdges;
                W           = fineLevel.Wstrong;
                strongEdges = nnz(W)/2;
                if (strongEdges < numEdges);
                    details.isExactElimination = false;
                    if (obj.myLogger.debugEnabled)
                        obj.myLogger.debug('Weak edge elimination:  edges=%8d  strong edges=%8d\n', ...
                            numEdges, strongEdges);
                    end
                    A       = spdiags(sum(W,2), 0, n, n) - W; %B=
                    degree  = sum(W ~= 0, 1);
                end
%             else
%                 B = A;
            end

            % Elimination stages. Performed until A is scalar or no more
            % nodes can be eliminated.
            %while (n > obj.options.maxDirectSolverSize)
            while (stageNum < obj.options.eliminationMaxStages)
                % Compute Z and F sets
                [f, c]  = lowDegreeNodes(A, degree, obj.options.eliminationMaxDegree);
                nf      = numel(f);
                nc      = numel(c);
                if (isempty(c) || (nf <= obj.options.minEliminationFraction*n) || ...
                        (n <= obj.options.maxDirectSolverSize))
                    if (obj.myLogger.debugEnabled)
                        obj.myLogger.debug('stopping elimination: total=%8d  f=%8d  c=%8d\n',...
                            n, nf, nc);
                    end
                    break;
                end
                stageNum = stageNum+1;
                
                % Reallocate if necessary
                if (sz < stageNum)
                    newSz       = 2*sz;
                    temp        = cell(1,newSz);
                    temp(1:sz)  = stage;
                    stage       = temp;
                    sz          = newSz;
                end
                
                % Time P + coarse operator time
                tStart = tic;
                
                % Save this stage's transfer operators and node sets. Note:
                % P is not caliber-1!
                
                %fprintf('eliminationOperators()\n');
                index       = zeros(1,n);
                index(c)    = 1:numel(c);
                index(f)    = 1:numel(f);
                [R, q]      = eliminationOperators(A, f, index);
                P           = R';
                
                stage{stageNum}     = struct('P', P, 'PT', R, 'q', q, 'f', f, 'c', c, 'n', n);
                details.nnzFNodes   = details.nnzFNodes + nnz(R);
                
                % Compute coarse operator = Schur complement
                Acc             = A(c,c);
                A               = Acc + A(c,f)*P;
                n               = size(A,1);
                if ((n > 1) && ~isempty(find(~diag(A), 1)))
                    error('Zero diagonal element in eliminated operator. Could be due to very small edge weights in original matrix.');
                end
                %A               = galerkinElimination(A, R, status, c, index);
                details.timeCoarsening = details.timeCoarsening + toc(tStart);
                
                if (obj.myLogger.debugEnabled)
                    if (n <= 1)
                        numEdges = 0;
                    else
                        numEdges = (nnz(A)-n)/2;
                    end
                    if (obj.myLogger.debugEnabled)
                        obj.myLogger.debug('Elimination stage %#2d: total=%8d  f=%8d  c=%8d  edges=%8d\n',...
                            stageNum, n, nf, size(A,1), numEdges);
                    end
                end

                % Prepare for the next elimination stage
                %B = A; % Exclude weak edges only in the first elimination round; from the second on, on use A
                %degree          = sum(W ~= 0, 1);
                degree          = sum(A ~= 0, 1) - 1; % Assuming singly-connected graph = all diagonal elements are non-zero
            end
            
            if (stageNum == 0)
                % Did not eliminate anything
                coarseLevel     = [];
                target.state = amg.setup.CoarseningState.AGG;
            else
                % Clear TV data at fine level, not needed if we use elimination
                fineLevel.x = [];
                
                % Save entire elimination as the next coarse level
                coarseLevel = amg.setup.CoarseningStrategy.LEVEL_FACTORY.newInstance(...
                    amg.level.LevelType.ELIMINATION, ...
                    target.index, ...
                    amg.setup.CoarseningState.ELIMINATION, ...
                    target.relaxFactory, ...
                    fineLevel.K, ...
                    'name', problem.g.metadata.name, ...
                    'fineLevel', fineLevel, 'stage', stage(1:stageNum), 'A', A, ...
                    'cycleType', obj.options.cycleType, ...
                    'isExactElimination', details.isExactElimination);
                fineLevel.setAboveEliminationLevel(target.relaxFactory, f, c, stage{stageNum});
                % Can't eliminate any more
                target.state = amg.setup.CoarseningState.AGG;
            end
            
            % Coarsening statistics do not apply here because we only
            % constructed the finest level and didn't really coarsen
            hcr     = 0;
            beta    = 0;
            %             if (fineLevel.hasDisconnectedNodes)
            %                 nu = 0;
            %             else
            nu = target.options.nuDefault;
            %             end
        end
    end
    
    %======================== PRIVATE METHODS =========================
    methods (Access = protected)
        function newState = updateStateInternal(dummy1, dummy2)
            % Return the next coarsening state. This method also updates
            % the internal state of this object.
            newState = amg.setup.CoarseningState.LOW_IMPACT_ELIMINATION;
        end
    end
end