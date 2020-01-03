classdef (Sealed) Setup < handle
    %SETUP Multigrid cycle setup data structure.
    %   This class contains the data structures required for a multilevel
    %   cycle: levels, number of relaxation sweeps at each level, predicted
    %   efficiency measures. This class is immutable.
    %
    %   See also: AGGREGATORHCR.
    
    %=========================== PROPERTIES ==============================
    properties (Constant, GetAccess = private)
        myLogger = core.logging.Logger.getInstance('amg.setup.Setup')
    end
    
    properties (Dependent)
        nodeComplexity          % Total # graph nodes at all levels, relative to the finest level
        edgeComplexity          % Total # graph edges at all levels, relative to the finest level
        work                    % multilevel cycle work at each level, relative to a finest level relaxation cost
        cycleComplexity         % total multilevel cycle complexity, relative to a finest level relaxation cost
        
        state                   % Level type array
        nodes                   % # nodes of each level
        edges                   % # nodes of each level
        degreeL2                % L2-average node degree
%        numComponents           % # connected components at each level

%        hcr                     % HCR ACF at each level (L x 1)
%        beta                    % HCR ACF per unit work at each level (L x 1)
        pComplexity             % Interpolation operator complexity
        relaxComplexity         % Relaxation sweeep complexity
        numTv                   % # test vectors at all levels
        
        nu                      % Total number of relaxations to perform at each level (L x 1)
        nuPre                   % # pre-CGC relaxations to perform at each level (L x 1)
        nuPost                  % # post-CGC relaxations to perform at each level (L x 1)
        cycleIndex              % Cycle index at each level
        
        % Setup time breakdown
        timeCoarsening          % P + Galerkin time per edge
        timeRelax               % TV relax time per edge
        timeOther               % Rest of setup time per edge
    end
    
    properties (GetAccess = public, SetAccess = private)
        problem                 % Computational problem for which this setup is for
        designCycleIndex        % Design cycle index
        numLevels               % Number of levels constructed L
        level                   % Level cell array (L x 1). 1=finest, L=coarsest
%        finestComponentIndex    % finest graph connected components
%        finestNumComponents     % finest level # connected components
%        levelComponentIndex     % cell array of graph connected components at all levels
        
        info                    % L x K matrix containing level meta data, where K=#meta data items per column
    end
    properties (GetAccess = private, SetAccess = private)
        nuDesign                
    end
    
    %======================== CONSTRUCTORS ============================
    methods % Should ideally be package-private; instantiate using SetupBuilder.build()
        function obj = Setup(builder)
            % Populate this object.
            
            % Populate internal fields from builder
            L                        = builder.numLevels;
            obj.numLevels            = L;
            range                    = 1:L;
            obj.problem              = builder.problem;
            obj.level                = builder.level(range);
%            obj.finestComponentIndex = builder.finestComponentIndex;
%            obj.finestNumComponents  = builder.finestNumComponents;
%            obj.levelComponentIndex  = builder.levelComponentIndex;
            obj.info                 = builder.info(range,:);
            obj.designCycleIndex     = builder.designCycleIndex;
            obj.nuDesign             = builder.nuDesign;
        end
    end
    
    %======================== METHODS =================================
    methods
        function disp(obj)
            % Display a textual representation of a Setup object.
            fprintf('Multi-level setup\n');
            fprintf('\t#levels          = %d\n', obj.numLevels);
            fprintf('\tDesign gamma     = %.1f\n', obj.designCycleIndex);
            %fprintf('\t# components = %d\n', obj.finestNumComponents);
            %fprintf('\tNode  complexity = %.3f\n', obj.nodeComplexity);
            fprintf('\tEdge  complexity = %.3f\n', obj.edgeComplexity);
            fprintf('\tCycle complexity = %.3f\n', obj.cycleComplexity);
            fprintf('%-2s %-8s %-8s %-8s %-6s %-7s %-7s %-3s %-4s %-5s %-3s\n', ...
                'l', 'Type', 'Nodes', 'Edges', 'NodeR', 'EdgeR', 'DegL1', ...
                'Nu', 'Gam', 'Work', 'TV');
            fprintf('=======================================================================\n');
            state           = obj.state;
            nodes           = obj.nodes;
            edges           = obj.edges;
            nodeRatio       = [1; 1./fac(nodes)];
            edgeRatio       = [1; 1./fac(edges)];
            degreeL1        = 2*edges./nodes;
            nu              = obj.nu;
            cycleIndex      = obj.cycleIndex;
            K               = obj.numTv;
            W               = obj.work;
            for l = 1:obj.numLevels
                s = state(l);
                fprintf('%-2d %-8s %-8d %-8d %-6.3f %-6.3f %-7.2f %-3d %-4.1f %-5.2f %-3d\n', ...
                    l, s.details.name, nodes(l), edges(l), ...
                    nodeRatio(l), edgeRatio(l), degreeL1(l), ...
                    nu(l), cycleIndex(l), W(l), K(l));
            end
        end
        
        function dispTime(obj)
            % Display setup time breakdown.
            state            = obj.state;
            nodes            = obj.nodes;
            edges            = obj.edges;
            degreeL1         = 2*edges./nodes;
            degreeL2         = obj.degreeL2;
            timeCoarsening   = obj.timeCoarsening;
            timeRelax        = obj.timeRelax;
            timeOther        = obj.timeOther;
            timeTotal        = obj.timeCoarsening + obj.timeRelax + obj.timeOther;
            timeSetupPerEdge = sum(timeTotal.*edges/edges(1));
            
            fprintf('Setup time breakdown:\n');
            fprintf('\tEdge complexity        = %.3f\n', obj.edgeComplexity);
            fprintf('\tTotal Setup time/edge  = %8.1e\n', timeSetupPerEdge);
            fprintf('\n');
            fprintf('%-2s %-8s %-8s %-8s %-7s %-7s %-8s %-8s %-8s %-8s %-8s\n', ...
                'l', 'Type', 'Nodes', 'Edges', 'DegL1', 'DegL2', ...
                'tCoarsen', 'tRelax', 'tOther', 'tTotal', 'tTotal-f');
            fprintf('==========================================================================================\n');
            for l = 1:obj.numLevels
                s = state(l);
                fprintf('%-2d %-8s %-8d %-8d %-7.3f %-7.3f %-8.1e %-8.1e %-8.1e %-8.1e %-8.1e\n', ...
                    l, s.details.name, nodes(l), edges(l), ...
                    degreeL1(l), degreeL2(l), ...
                    timeCoarsening(l), timeRelax(l), timeOther(l), timeTotal(l), timeTotal(l)*edges(l)/edges(1));
            end
            %fprintf('\n');
            fprintf('%-45s %-8.1e %-8.1e %-8.1e %-8.1e %-8.1s\n', ...
                'Total time per finest edge', ...
                sum(obj.timeCoarsening.*obj.edges/obj.edges(1)), ...
                sum(obj.timeRelax.*obj.edges/obj.edges(1)), ...
                sum(obj.timeOther.*obj.edges/obj.edges(1)), ...
                sum(timeTotal.*obj.edges/obj.edges(1)), ...
                '-');
            fprintf('%-45s %7.1f%% %7.1f%% %7.1f%% %7.0f%% %-8.1s\n', ...
                '% of total time per finest edge', ...
                100*sum(obj.timeCoarsening.*obj.edges/obj.edges(1))/timeSetupPerEdge, ...
                100*sum(obj.timeRelax.*obj.edges/obj.edges(1))/timeSetupPerEdge, ...
                100*sum(obj.timeOther.*obj.edges/obj.edges(1))/timeSetupPerEdge, ...
                100*sum(timeTotal.*obj.edges/obj.edges(1))/timeSetupPerEdge, ...
                '-');
        end
        
        function clear(obj)
            % Free memory. Keep metadata only, discard the level hierarchy
            % and large arrays.
            obj.level = [];
            obj.problem = [];
%            obj.finestComponentIndex = [];
%            obj.levelComponentIndex = [];
        end
        
        function setLevel(obj, l, lev)
            % Set level l to an externally-built level.
            obj.level{l} = lev;
            % TODO: update info!
        end
        
        function setCycleIndex(obj, l, gamma)
            % Set the number of relaxation sweeps at level l to NU.
            obj.info(l,amg.setup.SetupColumn.CYCLE_INDEX) = gamma;
        end
        
        function setNu(obj, levels, nu)
            % Set the number of relaxation sweeps at level l to NU.
            import amg.setup.CoarseningState;
            import amg.setup.SetupColumn;

            for l = levels
                if (l == obj.numLevels)
                    s = CoarseningState.AGG;
                else
                    lev = obj.level{l+1};
                    s = lev.state;
                end
                [nuTotal, nuPre, nuPost] = amg.setup.Setup.splitNu(s, nu, obj.nuDesign);
                obj.info(l, SetupColumn.NU     ) = nuTotal;
                obj.info(l, SetupColumn.NU_PRE ) = nuPre;
                obj.info(l, SetupColumn.NU_POST) = nuPost;
            end
        end
        
        function index = finestHcrLevel(obj)
            % Return the index of the finest level at which HCR computation
            % is non-trivial. If not found, returns an empty index.
            
            index = [];
            s = obj.state;
            for l = 1:obj.numLevels-1
                sc = s(l+1);
                if (~sc.details.isElimination)
                    index = l;
                    break;
                end
            end
        end
        
        function small = filterLevels(obj, type, threshold)
            % Return the indices of levels that don't affect the work much
            % and at which nu can be set to a number != 1 (i.e. they are
            % directly above a AGG level).
            
            % A single relaxation work at this level relative to finest
            % relaxation work
            %             relaxWork = (obj.relaxComplexity ...
            %                 .*(obj.nodes/obj.nodes(1)).*cumprod([1;
            %                 obj.cycleIndex(1:end-1)])) ... /
            %                 obj.finestRelaxComplexity;
            relaxWork = obj.edges/max(obj.edges(1),1);
            s = obj.state;
            
            if (strcmp(type, 'le'))
                relevantLevels = find(relaxWork <= threshold)';
            elseif (strcmp(type, 'ge'))
                relevantLevels = find(relaxWork >= threshold)';
            elseif (strcmp(type, 'lt'))
                relevantLevels = find(relaxWork < threshold)';
            elseif (strcmp(type, 'gt'))
                relevantLevels = find(relaxWork > threshold)';
            else
                error('Unsupported level type ''%s''', type);
            end
            
            small = [];
            for l = setdiff(relevantLevels, obj.numLevels)
                sc = s(l+1);
                if (~sc.details.isElimination)
                    small = [small l]; %#ok
                end
            end
        end
        
        function flag = isAboveElimination(obj, l)
            % Return true if level L is the next-finer level above an elimination level.
            flag = ((l < obj.numLevels) && obj.level{l+1}.isElimination);
        end
    end
    
    %======================== GET & SET ===============================
    methods
        function w = get.nodeComplexity(obj)
            % Return the total # graph nodes at all levels, relative to the
            % finest level.
            nodes = obj.nodes;
            w = sum(nodes)/max(nodes(1),1);
        end
        
        function w = get.edgeComplexity(obj)
            % Return the total # graph edges at all levels, relative to the
            % finest level.
            edges = obj.edges;
            w = sum(edges)/max(edges(1),1);
        end
        
        function w = get.work(obj)
            % Return the multilevel cycle complexity at level l, relative
            % to a finest level relaxation cost.
            wFinest = obj.finestRelaxComplexity;
            if (wFinest == 0)
                w = zeros(numel(obj.relaxComplexity));
            else
                w = ((obj.nu .* obj.relaxComplexity + 2*obj.pComplexity)...
                    .*(obj.nodes/obj.nodes(1)).*cumprod([1; obj.cycleIndex(1:end-1)])) ...
                    / wFinest;
            end
        end
        
        function w = get.cycleComplexity(obj)
            % Return the multilevel cycle complexity, relative to a finest
            % level relaxation cost.
            w = sum(obj.work);
        end
        
        function col = get.state(obj)
            % Setup column: state.
            col = amg.setup.CoarseningState(obj.info(:,amg.setup.SetupColumn.STATE));
        end
        
        function col = get.nodes(obj)
            % Setup column: nodes.
            col = obj.info(:,amg.setup.SetupColumn.NODES);
        end
        
        function col = get.edges(obj)
            % Setup column: edges.
            col = obj.info(:,amg.setup.SetupColumn.EDGES);
        end
         
        function col = get.degreeL2(obj)
            % Setup column: L2 average degree.
            col = obj.info(:,amg.setup.SetupColumn.DEGREE_L2);
        end
        
%         function col = get.numComponents(obj)
%             % Setup column: #connected components.
%             col = obj.info(:,amg.setup.SetupColumn.NUM_COMPONENTS);
%         end
%        
%         function col = get.hcr(obj)
%             % Setup column: HCR ACF.
%             col = obj.info(:,amg.setup.SetupColumn.HCR);
%         end
%         
%         function col = get.beta(obj)
%             % Setup column: HCR ACF per unit work.
%             col = obj.info(:,amg.setup.SetupColumn.BETA);
%         end
        
        function col = get.nu(obj)
            % Setup column: nu.
            col = obj.info(:,amg.setup.SetupColumn.NU);
        end
        
        function col = get.nuPre(obj)
            % Setup column: nuPre.
            col = obj.info(:,amg.setup.SetupColumn.NU_PRE);
        end
        
        function col = get.nuPost(obj)
            % Setup column: nuPost.
            col = obj.info(:,amg.setup.SetupColumn.NU_POST);
        end
        
        function col = get.pComplexity(obj)
            % Setup column: P complexity.
            col = obj.info(:,amg.setup.SetupColumn.P_COMPLEXITY);
        end
        
        function col = get.relaxComplexity(obj)
            % Setup column: relaxation complexity.
            col = obj.info(:,amg.setup.SetupColumn.RELAX_COMPLEXITY);
        end
        
        function col = get.cycleIndex(obj)
            % Setup column: cycle index.
            col = obj.info(:,amg.setup.SetupColumn.CYCLE_INDEX);
        end
        
        function col = get.numTv(obj)
            % Setup column: # test vectors
            col = obj.info(:,amg.setup.SetupColumn.NUM_TV);
        end
        
        function col = get.timeCoarsening(obj)
            % Setup column: Galerkin time per edge.
            col = obj.info(:,amg.setup.SetupColumn.TIME_COARSENING);
        end
        
        function col = get.timeRelax(obj)
            % Setup column: TV relax time per edge.
            col = obj.info(:,amg.setup.SetupColumn.TIME_RELAX);
        end
        
        function col = get.timeOther(obj)
            % Setup column: other setup time.
            col = obj.info(:,amg.setup.SetupColumn.TIME_OTHER);
        end
    end
    
    %======================== STATIC METHODS ==========================
    methods (Static)
        function [nu, nuPre, nuPost] = splitNu(state, n, nuDesign)
            % Split and return #relaxations n at the next-finer level of a
            % coarse level of type STATE.
            import amg.setup.CoarseningState;
            
            switch (state)
                case {CoarseningState.FINEST, CoarseningState.ELIMINATION}
                    % Elimination coarsening: #relaxations are always (0,1)
                    % because relaxation is a back-substitution operation.
                    % F-relaxation is actually executed.
                    nu      = 0;
                    nuPre   = 0;
                    nuPost  = 0;
                case CoarseningState.AGG,
                    nu = n;
                    [nuPre, nuPost] = splitNu(n, nuDesign);
            end
        end
    end
    
    %======================== PRIVATE METHODS =========================
    methods (Access = private)
        function w = finestRelaxComplexity(obj)
            % Finest level relaxation complexity [operations per node].
            % Works even when #nodes=0.
            numNodes = obj.nodes(1);
            if (numNodes == 0)
                w = 0;
            else
                w = 4*obj.edges(1)/numNodes;
            end
        end
        
        function s = printAcf(obj, l, x)
            if (l < obj.numLevels)
                state = amg.setup.CoarseningState(obj.state(l+1));
            end
            % Print ACF-type x statistic for level l.
            if (isempty(x) || (l == obj.numLevels) || state.details.isElimination)
                s = '-';
            else
                s = sprintf('%-8.3f', x);
            end
        end
    end
end