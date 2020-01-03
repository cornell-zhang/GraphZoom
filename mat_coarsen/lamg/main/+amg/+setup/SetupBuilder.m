classdef (Sealed) SetupBuilder < amg.api.Builder & amg.api.HasOptions
    %SETUPBUILDER A builder of a Setup instance.
    %   Due to MATLAB's lack of support for friend classes and
    %   package-level access, we duplicate the fields of class Setup that
    %   are mutable during construction. Setup is immutable and public,
    %   while this class is mutable but package-private.
    %
    %   See also: AGGREGATORHCR.
    
    %=========================== PROPERTIES ==============================
    properties (Constant, GetAccess = private)
        logger = core.logging.Logger.getInstance('amg.setup.SetupBuilder')
    end
    
    properties (GetAccess = public, SetAccess = private)
        % Mandatory construction arguments
        problem                 % Computational problem for which this setup is for
        nuDesign                % Strategy of splitting the #relaxations at each levels to pre- and post-
        handlers                % a map of state-to-state-handler (=coarsening-state-to-coarsening-strategy)
        designCycleIndex        % Design cycle index
        
        numLevels = 0           % Current number of levels stored in this object
        level                   % Level cell array (L x 1). 1=finest, L=coarsest
        info                    % L x K matrix containing level meta data, where K=#meta data items per column
        
%        finestComponentIndex    % finest graph connected components
%        finestNumComponents     % finest level # connected components
%        levelComponentIndex     % cell array of graph connected components at all levels
    end
    properties (GetAccess = private, SetAccess = public)
        % Dependency injections
        assembleComponents = true % Assemble components (if true) or assume a singly-connected graph (if false)
    end
    properties (Dependent)
        coarsestLevel           % Coarsest level to date
    end
    properties (Dependent, SetAccess = private)
        sz                      % Allocation size of all arrays
    end
    
    %======================== CONSTRUCTORS ============================
    methods
        function obj = SetupBuilder(problem, options)
            % Initial array allocation.
            obj = obj@amg.api.HasOptions(options);
            obj.problem             = problem;
            obj.designCycleIndex    = options.cycleIndex;
            obj.nuDesign            = options.nuDesign;
            obj.reAllocate(10);
            % Default factory
            obj.setCoarseningFactory(amg.setup.CoarseningStrategyFactory);
        end
    end
    
    %======================== METHODS =================================
    methods
        function addLevel(obj, coarseLevel, nu, details)
            % Append a new coarsest level to the hierarchy.
            import amg.setup.SetupColumn;
            
            % Add level to level array. Note: some stats are added to the
            % fine level (index lc), while coarseLevel is saved under index
            % lf in the level array
            if (obj.numLevels == obj.sz)
                obj.reAllocate(2*obj.sz);
            end
            l               = obj.numLevels;
            lc              = l+1;
            obj.numLevels   = lc;
            obj.level{lc}   = coarseLevel;
            ncEdges         = coarseLevel.g.numEdges;
            nc              = coarseLevel.g.numNodes;
            state           = coarseLevel.state;
            
            % Update coarse level stats
            obj.info(lc, SetupColumn.STATE) = state;
            obj.info(lc, SetupColumn.NODES) = nc;
            obj.info(lc, SetupColumn.EDGES) = ncEdges;
            obj.info(lc, SetupColumn.DEGREE_L2) = lpnorm(coarseLevel.g.degree);
            
            % Each standard relaxation step requires +,* per non-zero in A
            % Set work of a direct solver at coarsest level to 0
            if (nc <= obj.options.maxDirectSolverSize)
                obj.info(lc, SetupColumn.RELAX_COMPLEXITY) = 0;
            else
                obj.info(lc, SetupColumn.RELAX_COMPLEXITY) = 4*ncEdges/nc;
            end
            
            % Update next-finer level's stats
            if (state ~= amg.setup.CoarseningState.FINEST)
                lf          = lc-1;
                fineLevel   = obj.level{lf};
                nfEdges     = fineLevel.g.numEdges;
                alpha       = (1.0 * coarseLevel.g.numNodes) / fineLevel.g.numNodes;
                alphaEdge   = (1.0 * ncEdges) / nfEdges;
                
                [nuTotal, nuPre, nuPost] = amg.setup.Setup.splitNu(coarseLevel.state, nu, obj.nuDesign);
                obj.info(lf, SetupColumn.NU     ) = nuTotal;
                obj.info(lf, SetupColumn.NU_PRE ) = nuPre;
                obj.info(lf, SetupColumn.NU_POST) = nuPost;
                obj.info(lf, SetupColumn.NUM_TV ) = size(fineLevel.x, 2);
                %obj.info(lf, SetupColumn.HCR    ) = hcr;
                %obj.info(lf, SetupColumn.BETA   ) = beta;
                
                % Save times
                obj.info(lf, SetupColumn.TIME_COARSENING)   = details.timeCoarsening/nfEdges;
                obj.info(lf, SetupColumn.TIME_RELAX)        = details.timeRelax/nfEdges;
                obj.info(lf, SetupColumn.TIME_OTHER)        = (details.timeTotal - details.timeCoarsening - details.timeRelax)/nfEdges;
                
                % All estimated operator complexities are per node
                if (coarseLevel.isElimination)
                    %--- Elimination ---
                    
                    obj.info(lf, SetupColumn.CYCLE_INDEX     ) = 1.0;
                    % Elimination interpolation P to an F-node uses all its
                    % neighbors (eacj Pfc non-zero requires +,=). But since
                    % only restriction is required (interpolation is
                    % arbitary), we half the complexity
                    obj.info(lc, SetupColumn.P_COMPLEXITY    ) = 0.5*2*details.nnzFNodes/nc;
                    % Only F-relaxation is required at the fine level (even
                    % though a full relaxation sweep is currently
                    % implemented). Each step requires +,* per non-zero in
                    % Afc.
                    obj.info(lf, SetupColumn.RELAX_COMPLEXITY) = 2*details.nnzFNodes/nc;
                else
                    %--- AGG coarsening ---
                    
                    if (~coarseLevel.isElimination)
                        finestNumEdges = obj.level{1}.g.numEdges;
                        numEdges = fineLevel.g.numEdges;
                        if (obj.logger.debugEnabled)
                            obj.logger.debug('#edges = %d  finest edges = %d\n', numEdges, finestNumEdges);
                        end
                        if (obj.options.cycleDynamicIndex && (numEdges <= 0.1 * finestNumEdges))
                        %if (obj.options.cycleDynamicIndex)
                            % Dynamic cycle index at intermediate coarse
                            % grids that maximizes cycling for the
                            % coarsening ratio
                            %cycleIndex = min(2.0, max(obj.designCycleIndex, obj.options.coarseningWorkGuard / alphaEdge));
                            cycleIndex = max(1.0, min([2.0, obj.designCycleIndex, obj.options.coarseningWorkGuard / alphaEdge]));
                            if (obj.logger.debugEnabled)
                                obj.logger.debug('Setting cycle index to %.1f (guard)\n', cycleIndex);
                            end
                        else
                            % Static index
                            cycleIndex = obj.designCycleIndex;
                            if (obj.logger.debugEnabled)
                                obj.logger.debug('Setting cycle index to %.1f (fine level)\n', cycleIndex);
                            end
                        end
                        obj.info(lf, SetupColumn.CYCLE_INDEX     ) = cycleIndex;
                    end
                    
                    % Caliber-1 P: 1 operation per fine node (interp
                    % coefficients = 1)
                    obj.info(lc, SetupColumn.P_COMPLEXITY    ) = 1/alpha;
                end
            end
        end
    end
    
    %======================== IMPL: Builder ===========================
    methods
        function target = build(obj)
            % Build the target Setup object.
            import amg.setup.SetupColumn;
            
            % Don't compute connected components any more. Assuming singly
            % connected graph.
%            obj.info(1:obj.numLevels, SetupColumn.NUM_COMPONENTS) = 0;
            
            target = amg.setup.Setup(obj);
            
            % Treat the one-level case
            if (obj.numLevels == 1)
                finest = 1;
                n1 = obj.level{finest}.g.numNodes;
                if (n1 < obj.options.maxDirectSolverSize)
                    % Direct solver
                    target.setNu(finest, 0);
                else
                    % Relaxation solver
                    target.setNu(finest, 1);
                end
            end
            
            % Increase nu at very coarse levels
            %if (obj.options.cycleDynamicIndex)
            % Not good for at least one problem: intermediate level does
            % not have enough smoothing with 2 relax, causing the entire
            % cycle to slow down.
            %                target.setNu(target.filterLevels('le', 0.05),
            %                2);
            %target.setNu(target.filterLevels('le', 0.02), 3); end
            
            % 1-level solver = relaxation
            if (target.numLevels == 1)
                target.setNu(1:target.numLevels, 1);
            end           
        end
        
        function [nu, nuPre, nuPost] = getNuArrays(obj)
            % Return all relaxation number (nu) arrays.
            range = 1:obj.numLevels;
            if (obj.numLevels == 1)
                % 1-level method = relaxation
                nu      = 1;
                nuPre   = 1;
                nuPost  = 0;
            else
                nu      = builder.nu(range);
                nuPre   = builder.nuPre(range);
                nuPost  = builder.nuPost(range);
            end
        end
    end
    
    %======================== GET & SET ===============================
    methods
        function sz = get.sz(obj)
            % Return the allocation size of this object.
            sz = numel(obj.level);
        end
        
        function coarsestLevel = get.coarsestLevel(obj)
            % Return the Coarsest level to date
            if (obj.numLevels == 0)
                coarsestLevel = [];
            else
                coarsestLevel = obj.level{obj.numLevels};
            end
        end

        function setCoarseningFactory(obj, coarseningFactory)
            % Set a new coarsening strategy factory.
            obj.handlers = amg.setup.CoarseningState.newHandlerMap(obj.options, coarseningFactory);            
        end
    end
    
    %======================== PRIVATE METHODS =========================
    methods (Access = private)
        function reAllocate(obj, sz)
            % (Re-)allocate all arrays to size SZ. SZ must be >= current
            % allocation size.
            
            % Save old arrays in buffers
            oldLevel    = obj.level;
            oldInfo     = obj.info;
            
            % Rellocate arrays
            obj.level   = cell(sz, 1);
            obj.info    = zeros(sz, amg.setup.SetupColumn.numColumns);
            
            % Copy old data
            if (obj.numLevels > 0)
                range             = 1:obj.numLevels;
                obj.level(range)  = oldLevel(range);
                obj.info(range,:) = oldInfo(range,:);
            end
        end
    end
end