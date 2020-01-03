classdef (Sealed) Options < handle %matlab.mixin.Copyable
    %OPTIONS Multi-level algorithm options.
    %   Includes both model parameters and cycle parameters. Sets default
    %   values for parameters that can be overriden by the user.
    
    %======================== CONSTANTS ===============================
    
    %======================== MEMBERS =================================
    properties
        %-------------------------
        % Computational problem
        %-------------------------
        problemType = 'laplacian'               % Problem type (e.g., 'laplacian', 'resistance')
        sourceNode = 1                          % Source node s, for flow problems
        sincNode = 2                            % Sinc node t, for flow problems
        minWeightAllowed = -0.1                 % Minimum weight w_{uv} allowed relative to max(max_s w_{us}, max_s w_{sv})
        x0 = []                                 % Initial guess (applicable if non-empty)
        numEigenpairs = 1                       % Number of desired eigenpairs (in an eigenproblem)
        
        %-------------------------
        % Relaxation scheme
        %-------------------------
        relaxType = 'gs'                        % Relaxation scheme (smoother). [gs]|sgs|jacobi
        relaxOmega = 1.0                        % Over-relaxation parameter
        relaxAdaptive = false                   % Run local adaptive GS sweeps after each global sweeps or not
        
        %-------------------------
        % Setup phase
        %-------------------------
        minCoarseSize = 300 %200                % A guide for the minimum coarsest level size
        maxCoarseRelaxAcf = 0.3 %0.7            % If relaxation converges at this rate or faster, this becomes the coarsest level
        relaxAcfMinSweeps = 7                   % Minimum number of sweeps to run to estimate relax ACF
        setupNumAggLevels = 100                 % maximum #aggregation coarsening levels to construct during the setup phase
        setupNumLevels = 100                    % maximum TOTAL # of coarsening levels to construct during the setup phase
        %setupNumLevels = 3                    % maximum TOTAL # of coarsening levels to construct during the setup phase
        setupSave = false                       % If true, saves level hierarchy to an m-file
        cycleIndex = 1.5                        % Solution cycle index. Also the design cycle index during setup phase.
        tvNum = 4    %8                         % # initial test vectors (TVs) at each level. At least 3-4 for a meaningful affinity between a node pair.
        tvMax = 10                              % Maximum allowed #TVs
        tvIncrement = 1                         % #TVs to add upon each aggregation coarsening
        tvSweeps = 4                            % # global sweeps to perform on each initial TV
        tvNumLocalSweeps = 0                    % # local sweeps to perform on each TV at each node i during coarsening (then retract)
        tvInitialGuess = 'random'               % Type of TV initial guess (random/geometric)
        interpType = 'caliber1'                 % Interpolation operator type
        restrictType = 'transpose'              % Restriction operator type
        nuDesign = 'split_evenly_post'          % Strategy of splitting the relaxation sweep number nu at each level to nuPre and nuPost
        %disconnectedNodeTol = 1e-15             % A node is considered disconnected (0-degree) iff A(i,i) < this tolerance

        lda = 0.1                               % adding self-loop
        kpower = 2                              % power of graph filter

        %-------------------------
        % Setup - elimination
        %-------------------------
        elimination = false                      % Use elimination levels; if false, only aggregation levels are constructed
        eliminationMaxDegree = 4                % Max degree of low-degree nodes eliminated at elimination levels. Up to degree 3, no edges are added. Above 5 too many are typically added.
        eliminationMaxStages = 1000             % Maximum # of elimination stages to perform
        eliminationStrongEdgesBased = false     % Eliminate based on strong edges; ignore weak edges
        minEliminationFraction = 0.01           % Minimum required fraction of nodes to be eliminated in the elimination phase before it is switched to AGG coarsening

        %-------------------------
        % Setup - aggregation
        %-------------------------
        aggregationType = 'limited' %'hcr'      % Aggregation strategy
        aggregationUpdate = 'affinity-energy-mex'   % Strategy for updating TVs and affinities during an aggregation stage
        aggregationDegreeThreshold = 8          % Do not aggregate nodes with higher degree than this * median(degree)
        weakEdgeThreshold = 0.1      % Do not aggregate nodes whose graph weight is smaller than this threshold * |corresponding diagonal elements|
        secondDegreeNbhr = false                % Search within selected 2nd-degree neighbor of u?
        secondDegreeNbhrThreshold = 4           % Search within 2nd-degree neighbor of u whose degree < this * median(degree)
        subtractMean = false                    % Subtract the mean of X and Y before computing affinities. Currently respected only by the aggregationUpdate='recompute' strategy
        coarseningRatio = []                    % Coarsening ratio in each direction for aggregationType='geometric'
        minCoarseningRatio = 0.3                % Stop when this coarsening ratio (nc/nf) is reached
        strictMinCoarseningRatio = false        % Stop when this EXACT coarsening ratio is reached, possibly stopping an aggregation step early
        aggregateLooseNodes = true              % If true, all loose nodes are aggregated together. Otherwise, each one is its own aggregate
        maxHcrAcf = 0.5                         % Stop when this HCR rate is reached
        minBeta = 0.5                           % Stop when this beta is reached
        affinityType = 'L2'                     % Affinity (algebraic connection) estimation strategy
        betaIncreaseTol = 3.0                   % beta-increase tolerance to use in terminating all optimization loops
        maxHcrSweeps = 15                       % max # HCR sweeps to run for ACF estimation
        minAggregationStages = 1                % min # coarsening stages to generate
        maxAggregationStages = 2 %3 %2             % max # coarsening stages to generate before deciding on the best
        numAssociationSweeps = 1                % # sweeps over nodes per coarsening stage
        minAffinity = 0.5                       % Only neighbors J with |C(I,J)| >= minAffinity are considered as candidate seeds to aggregate I with
        deltaInitial = 0.0 %0.8 %0.9                      % initial delta value
        deltaDecrement = 0.7 %0.6                    % delta decrement factor
        ratioMax = 2.5                          % Maximum energy ratio in delta model
        aggregateSizeExchangeRate = 0.0         % Regularization parameter lam in minimizing E/Ec + lam*(aggregate size)
        maxAggregateSize = Inf                  % Maximum allowed aggregate size
        nuOptimization = false                  % Perform nu optimization (if true) or use nuDefault (if false)
        nuDefault = 3                           % #sweeps (nu) to use during coarsening stages. If nuOptimization is false, this is the aggregation design value for nu at all levels.
        nuMin = 1                               % min #sweeps (nu) to consider in nu optimization after coarse set is selected
        nuMax = 5                               % max #sweeps (nu) to consider in nu optimization after coarse set is selected
        addHcrVectors = false                   % Add HCR vectors to TV set during agregation or not
        coarseningWorkGuard = 0.7               % Bound on gamma*alpha during coarsening
        
        %-------------------------
        % Energy Correction
        %-------------------------
        energyCorrectionType = 'none'           % Energy correction strategy
        rhsCorrectionFactor = 4/3               % If non-empty, RHS is multiplied by a flat factor (mu). Usually used in conjunction with energyCorrectionType = 'flat'
        minRes = true                           % Do aAdaptive energy correction via MIN RES?
        energyCorrectionFactor = 0.5            % Energy correction multiplier to use if energyCorrectionType = 'constant'
        energyInterpolationCaliber = 2          % Max # coarse energy terms to fit to each fine energy term
        energyFitThreshold = 0.1                % Energy interpolation term fit threshold (stop adding terms when this threshold is reached)
        energyFitReductionThreshold = 0.7       % Energy interpolation term fit relative reduction threshold
        energyCaliber = 3                       % Energy interpolation max caliber
        energyMinWeight = 0.001                 % Minimum energy interpolation weight allowed
        energyResidualFactor = 0.1              % regularization/weight parameter lambda of residual term in energy correction fit functional
        
        %-------------------------
        % Cycle parameters
        %-------------------------
        cycleDynamicIndex = true                % Increase nu and cycle index to 0.8/coarsening ratio at very coarse AGG levels
        cycleRhsCorrection = true               % Apply RHS energy correction or not
        cycleEnergyCorrection = true            % Apply coarse level operator energy correction or not
        cycleNumLevels = 100                    % # levels to employ in the cycle
        cycleType = 'cs'                        % Cycle type ('cs'=Correction Scheme; 'fas'=Full Approximation Scheme
        cycleDirectSolver = true                % Use a direct solver or relaxations at the coarest level?
        maxDirectSolverSize = 200               % Max size for direct solver
        %cycleMinCoarsestSweeps = 10            % Minimum # relaxation sweeps to perform at coarsest level, if relaxation is used as a solver
        cycleMaxCoarsestSweeps = 400            % Maximum # relaxation sweeps to perform at coarsest level, if relaxation is used as a solver
        
        %-------------------------
        % AMG solution run
        %-------------------------
        pcg = false                             % Use LAMG as a CG preconditioner if true, or stand-alone solver if false
        numCycles = 200                          % max #cycles to run
        initialGuessNorm = 1e+0                 % Initial guess magnitude
        finalErrorNorm = 1e-15                  % Stop when this error norm is reached
        errorReductionTol = 1e-9 %1e-8          % Terminate when error norm is reduced by this factor
        errorNorm = @errorNormResidualUnscaled  % Error norm function to measure convergence with
		relativeNorm = @errorNormResidualRelative % norm(Ax-b)/norm(b)
        combinedIterates = 4                    % # iterates to combine at finest level - using AMG as a 'preconditioner' for iterate recombination. 1=no iterates are recombined
        
        %-------------------------
        % Miscellaneous
        %-------------------------
        logLevel = 1                            % Cycle logging level (higher=more verbose)
        plotCoarsening = false                  % Generate beta optimization plots or not
        plotLevels = false                      % Generate coarse level summary plots
        radius = 5                              % Coarse set plot: node marker radius [points]
        coarseningDebugEdgeIndex = -1           % Allow a breakpoint at this fine edge index for debugging
        coarseningDebugNodeIndex = []           % Allow a breakpoint at this fine node index for debugging
        energyFitDebug = false                  % Energy interpolation debugging printout flag
        energyOutFile = []                      % File name under the output directory to redirect debug printouts to; if not specified, they are printed to the console
        energyDebugEdgeIndex = -1               % Allow a breakpoint at this edge index for debugging
        numCyclesDetailedLog = 3                % #initial cycles to print more log information for
        randomSeed = []                         % Random seed for reproducibility
    end
    
    %======================== CONSTRUCTORS ============================
    methods
        function c = copy(obj)
            % Copy constructor.
            c = optionsOverride(amg.api.Options, obj);
        end
    end
    
    methods (Static)
        function options = fromStruct(d, varargin)
            % Parse a variable argument list to override default options
            % specified in D.
            import amg.api.Options
            p                   = inputParser;
            p.FunctionName      = 'Options';
            p.KeepUnmatched     = true;
            p.StructExpand      = true;

            % Computational problem
            Options.addField(p, d, 'problemType', @ischar);
            Options.addField(p, d, 'sourceNode', @isPositiveIntegral);
            Options.addField(p, d, 'sincNode', @isPositiveIntegral);
            Options.addField(p, d, 'minWeightAllowed', @isnumeric);
            Options.addField(p, d, 'x0', @(x)(isempty(x) || isnumeric(x) || isa(x, 'function_handle')));
            Options.addField(p, d, 'numEigenpairs', @isPositiveIntegral);

            % Relaxation options
            Options.addField(p, d, 'relaxType', @ischar);
            Options.addField(p, d, 'relaxAdaptive', @islogical);
            Options.addField(p, d, 'relaxOmega', @isnumeric);

            % Setup phase options            
            Options.addField(p, d, 'maxCoarseRelaxAcf', @(x)(isInRange(x,0,1,'closed')));
            Options.addField(p, d, 'setupNumAggLevels', @isPositiveIntegral);
            Options.addField(p, d, 'setupNumLevels', @isPositiveIntegral);
            Options.addField(p, d, 'setupSave', @islogical);
            Options.addField(p, d, 'cycleIndex', @isPositive);
            Options.addField(p, d, 'tvNum', @isPositive);
            Options.addField(p, d, 'tvIncrement', @isnumeric);
            Options.addField(p, d, 'tvSweeps', @isnumeric);
            Options.addField(p, d, 'tvNumLocalSweeps', @isnumeric);
            Options.addField(p, d, 'tvInitialGuess', @ischar);
            Options.addField(p, d, 'interpType', @ischar);
            Options.addField(p, d, 'restrictType', @ischar);
            Options.addField(p, d, 'nuDesign', @(x)(any(strcmp(x,{'split_evenly', 'split_evenly_post', 'pre', 'post'}))));
            %Options.addField(p, d, 'disconnectedNodeTol', @isPositive);
            
            % Setup - elimination options
            Options.addField(p, d, 'elimination', @islogical);
            Options.addField(p, d, 'eliminationMaxDegree', @isNonnegativeIntegral);
            Options.addField(p, d, 'eliminationMaxStages', @isPositiveIntegral);
            Options.addField(p, d, 'eliminationStrongEdgesBased', @islogical);            
            Options.addField(p, d, 'minEliminationFraction', @(x)(isInRange(x,0,1,'closed')));

            % Setup - aggregation options
            Options.addField(p, d, 'minCoarseSize', @isPositiveIntegral);
            Options.addField(p, d, 'aggregationType', @ischar);
            Options.addField(p, d, 'aggregationUpdate', @ischar);
            Options.addField(p, d, 'aggregationDegreeThreshold', @isnumeric);
            Options.addField(p, d, 'weakEdgeThreshold', @(x)(x >= 0));
            Options.addField(p, d, 'secondDegreeNbhr', @islogical);
            Options.addField(p, d, 'secondDegreeNbhrThreshold', @isnumeric);
            Options.addField(p, d, 'subtractMean', @islogical);
            Options.addField(p, d, 'coarseningRatio', @isnumeric);
            Options.addField(p, d, 'minCoarseningRatio', @(x)(isInRange(x,0,1,'closed')));
            Options.addField(p, d, 'strictMinCoarseningRatio', @islogical);
            Options.addField(p, d, 'aggregateLooseNodes', @islogical);
            Options.addField(p, d, 'maxHcrAcf', @(x)(isInRange(x,0,1,'closed')));
            Options.addField(p, d, 'minBeta', @(x)(isInRange(x,0,1,'closed')));
            Options.addField(p, d, 'affinityType', @(x)(any(strcmp(x,{'L2'}))));
            Options.addField(p, d, 'betaIncreaseTol', @isPositive);
            Options.addField(p, d, 'maxHcrSweeps', @isPositiveIntegral);
            Options.addField(p, d, 'minAggregationStages', @isPositiveIntegral);
            Options.addField(p, d, 'maxAggregationStages', @isPositiveIntegral);
            Options.addField(p, d, 'numAssociationSweeps', @isPositiveIntegral);
            Options.addField(p, d, 'minAffinity', @(x)(x >= 0));
            Options.addField(p, d, 'deltaDecrement', @isPositive);
            Options.addField(p, d, 'deltaInitial', @(x)(x >= 0));
            Options.addField(p, d, 'ratioMax', @isPositive);
            Options.addField(p, d, 'aggregateSizeExchangeRate', @(x)(x >= 0));
            Options.addField(p, d, 'maxAggregateSize', @isPositiveIntegral);
            Options.addField(p, d, 'nuOptimization', @islogical);
            Options.addField(p, d, 'nuDefault', @isNonnegativeIntegral);
            Options.addField(p, d, 'nuMin', @isPositiveIntegral);
            Options.addField(p, d, 'nuMax', @isPositiveIntegral);
            Options.addField(p, d, 'addHcrVectors', @islogical);
            Options.addField(p, d, 'coarseningWorkGuard', @isnumeric);

            % graph filter parameter
            Options.addField(p, d, 'lda', @isPositive);
            Options.addField(p, d, 'kpower', @isPositiveIntegral);
            
            % Energy Correction
            Options.addField(p, d, 'energyCorrectionType', @ischar);
            Options.addField(p, d, 'minRes', @islogical);
            Options.addField(p, d, 'rhsCorrectionFactor', @isPositive);
            Options.addField(p, d, 'energyCorrectionFactor', @isPositive);
            Options.addField(p, d, 'energyInterpolationCaliber', @isPositiveIntegral);
            Options.addField(p, d, 'energyFitThreshold', @isPositive);
            Options.addField(p, d, 'energyCaliber', @isPositive);
            Options.addField(p, d, 'energyMinWeight', @isnumeric);
            Options.addField(p, d, 'energyResidualFactor', @isPositive);

            % Cycle parameters
            Options.addField(p, d, 'cycleDynamicIndex', @islogical);
            Options.addField(p, d, 'cycleRhsCorrection', @islogical);
            Options.addField(p, d, 'cycleEnergyCorrection', @islogical);
            Options.addField(p, d, 'cycleType', @(x)(any(strcmp(x,{'cs', 'fas', 'eis'}))));
            Options.addField(p, d, 'cycleNumLevels', @isPositiveIntegral);
            Options.addField(p, d, 'cycleDirectSolver', @islogical);
            Options.addField(p, d, 'maxDirectSolverSize', @isPositive);
            Options.addField(p, d, 'cycleMaxCoarsestSweeps', @isPositiveIntegral);

            % AMG solution run            
            Options.addField(p, d, 'pcg', @islogical);
            Options.addField(p, d, 'numCycles', @isNonnegativeIntegral);
            Options.addField(p, d, 'initialGuessNorm', @isPositive);
            Options.addField(p, d, 'finalErrorNorm', @isPositive);
            Options.addField(p, d, 'errorReductionTol', @isPositive);
            Options.addField(p, d, 'errorNorm', @(x)(isa(x, 'function_handle')));
			Options.addField(p, d, 'relativeNorm', @(x)(isa(x, 'function_handle')));
            Options.addField(p, d, 'combinedIterates', @isNonnegativeIntegral);

            % Miscellaneous
            Options.addField(p, d, 'logLevel', @isNonnegativeIntegral);
            Options.addField(p, d, 'plotCoarsening', @islogical);
            Options.addField(p, d, 'plotLevels', @islogical);
            Options.addField(p, d, 'radius', @isPositive);
            Options.addField(p, d, 'coarseningDebugEdgeIndex', @isnumeric);
            Options.addField(p, d, 'coarseningDebugNodeIndex', @isnumeric);
            Options.addField(p, d, 'energyFitDebug', @islogical);
            Options.addField(p, d, 'energyOutFile', @(x)(isempty(x) || ischar(x)));
            Options.addField(p, d, 'energyDebugEdgeIndex', @isIntegral);
            Options.addField(p, d, 'numCyclesDetailedLog', @isPositiveIntegral);
            Options.addField(p, d, 'randomSeed', @(x)(isempty(x) || isPositiveIntegral(x)));

            p.parse(varargin{:});
            options = optionsOverride(d.copy(), p.Results);
        end
    end
    
    %======================== PRIVATE METHODS =========================
    methods (Static, Access = private)
        function addField(p, d, fieldName, validator)
            % Parse an options field.
            p.addParamValue(fieldName, d.(fieldName), validator);
        end
    end
end
