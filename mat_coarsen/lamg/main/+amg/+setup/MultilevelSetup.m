classdef MultilevelSetup < amg.api.HasOptions
    %MULTILEVELSETUP Constructs the multi-level data structure.
    %   This class builds a Setup object that contains list of
    %   increasingly-coarser levels to be used in the multigrid solution
    %   cycle.
    
    %======================== MEMBERS =================================
    properties (Constant, GetAccess = private)
        logger          = core.logging.Logger.getInstance('amg.setup.MultilevelSetup')
    end
    
    properties
        numAggLevels                    % Keeps track of the number of AGG levels during setup
        index                           % Keeps track of level #
    end
    % This should really be package-private-settable
    properties (GetAccess = private, SetAccess = public)
        state                           % Coarsening strategy used to construct the next-coarser level
    end
    % Problem-global services. These should really be package-private
    properties (GetAccess = public, SetAccess = private)
        aggregator                      % Aggregates nodes into a coarse set
        %acfComputer                     % Computes relaxation ACF
        relaxFactory                    % Standard relaxation scheme (factory)
    end

    %======================== CONSTRUCTORS ============================
    methods
        function obj = MultilevelSetup(options)
            % Construct a multi-level builder from options OPTIONS.
            obj = obj@amg.api.HasOptions(options);
            
            % Initialize problem-global factories
            obj.relaxFactory    = amg.relax.RelaxFactory(options);
            obj.aggregator      = amg.coarse.Aggregator(options); % Creates new coarse levels (aggregate sets)

%             % Computes relaxation ACF
%             obj.acfComputer = lin.api.AcfComputer(...
%                 'maxIterations', 10, ...
%                 'output', 'full', 'steadyStateTol', 1e-2, 'sampleSize', 2, ...
%                 'removeZeroModes', 'mean', ...
%                 'errorNorm', @errorNormL2, ...
%                 'acfEstimate', 'smooth-filter' ...
%                 );
        end
    end
    
    %======================== METHODS =================================
    methods (Sealed)
        function setup = build(obj, problem)
            % Build the list of levels for the problem PROBLEM from
            % options.
            global GLOBAL_VARS;
            
            % Initialization, initial allocation of setup information
            setupBuilder        = amg.setup.SetupBuilder(problem, obj.options);
            obj.state           = amg.setup.CoarseningState.FINEST;
            obj.numAggLevels    = 0;
            obj.index           = 1;
            coarseLevel         = [];
            fineLevel           = [];
            
            % Create a sequence of increasingly coarser levels
            while (obj.state ~= amg.setup.CoarseningState.DONE_COARSENING)
                if (obj.logger.debugEnabled)
                    obj.logger.debug('======= Constructing Level %3d, strategy %s =======\n', ...
                        setupBuilder.numLevels+1, obj.state.details.name);
                end

                % Save a reference to next-finer level
                if (~isempty(coarseLevel))
                    fineLevel = coarseLevel;
                end
                
                % Build the next coarse level. Update state accordingly
                handler = setupBuilder.handlers(int32(obj.state));
                tStart = tic;
                [coarseLevel, dummy1, dummy2, nu, details] = handler.build(obj, problem, setupBuilder.coarsestLevel); %#ok
                details.timeTotal = toc(tStart);
                
                % If a non-trivial level was constructed, initialize it and
                % save it in setup data structures
                if (~isempty(coarseLevel))
                    if (~isempty(fineLevel) && (coarseLevel.g.numNodes == fineLevel.g.numNodes))
                        error('MATLAB:MultilevelSetup:build', 'No nodes were eliminated during coarsening\n');
                    end
                    if (obj.options.plotLevels)
                        coarseLevel.plot();
                    end
                    setupBuilder.addLevel(coarseLevel, nu, details);
                    if (obj.logger.debugEnabled)
                        obj.logger.debug('Level size: nodes=%d, edges=%d\n', ...
                            coarseLevel.g.numNodes, coarseLevel.g.numEdges);
                    end
                end
                
            end % while (state ~= DONE_COARSENING)
            
            % Coarsest level: compute remaining #components that were not
            % separated at finer levels to obtain a non-singular matrix for
            % the direct solver
            if (isempty(coarseLevel))
                coarseLevel = fineLevel;
            end
            coarseLevel.setAsCoarsest();
            
            % Build target object from
            setup = setupBuilder.build();
            
            % Save level hierarchy for off-line debugging
            if (obj.options.setupSave)
                save(sprintf('%s/setup_%s.mat', GLOBAL_VARS.out_dir, problem.g.metadata.name), ...
                    'setup', 'problem');
            end
        end
    end
    
    %======================== GET & SET ===============================
    methods
        function set.state(obj, state)
            % Set a new coarsening state.
            obj.state = state;
            if (obj.logger.debugEnabled)
                obj.logger.debug('Updated state to %s\n', obj.state.details.name);
            end
        end
    end
    
    %======================== PRIVATE METHODS =========================
end
