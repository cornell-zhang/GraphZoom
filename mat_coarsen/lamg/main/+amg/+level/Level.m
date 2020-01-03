classdef Level < handle
    %LEVEL A single level in the multi-level cycle.
    %   This interface holds all data and operations pertinent to a single
    %   level in the multi-level cycle: right-hand-side, residual
    %   computation and single-level processes such as relaxation.
    
    %======================== MEMBERS =================================
    properties (Abstract, Dependent)
		P 						% Interpolation matrix (this -> fineLevel)
        T                       % Coarse type variable matrix (fineLevel -> this)
        coord                   % Node coordinates (if available in the graph)
        zeroMatrix              % True iff A = 0
    end
    properties (Dependent)
        weakEdgePortion         % Portion of weak edges in graph
    end
    properties
        x                       % Test vectors (n x K)
        r                       % A*x
    end
    properties (GetAccess = public, SetAccess = private)
        % meta data
        index                   % Index of this fine level in the Setup level array
        state                   % Coarsening strategy used to construct this level
        type                    % Level type
        name                    % Display name of this object
        fineLevel               % Next-finer level
        
        % Graph and operators
        g                       % Graph instance
%        rWeight                 % diag(A)^(-1/2) = normalized residual weights
        Wstrong                 % Filtered adjacency matrix of strong edge connections
        
        % Relaxation-related data structures
        relaxer                 % Relaxation scheme for A*x=b and A*x=0. Publicly accessible so that another object can run relaxation ACF experiments at this level
        K                       % Number of TVs
        %r                       % TV residuals r = A*x (n x K)
    end
    properties (GetAccess = public, SetAccess = protected)
        A                       % LHS matrix
%        B                       % Filtered LHS matrix containing strong connections only
    end
    properties (GetAccess = protected, SetAccess = private)
        args                    % Parsed construction argument struct
    end
    properties (GetAccess = private, SetAccess = private)
        relaxFactory            % Relaxation scheme factory
    end
    
    %======================== CONSTRUCTORS ============================
    methods (Access = protected)
        function obj = Level(type, index, state, relaxFactory, K, varargin)
            % Initialize a level for the linear problem A*x=0 from input
            % options.
            
            % Set level basic data
            obj.args            = obj.parseArgs(type, index, state, relaxFactory, K, varargin{:});
            obj.type            = obj.args.type;
            obj.index           = obj.args.index;
            obj.state           = obj.args.state;
            obj.name            = obj.args.name;
            obj.relaxFactory    = obj.args.relaxFactory;
            obj.K               = obj.args.K;
            obj.fineLevel       = obj.args.fineLevel;
            
            % Set level graph and operators
            [obj.g, obj.A]      = obj.initOperators(obj.args);
%            obj.rWeight         = full(diag(obj.A).^(-0.5));
            
            % Decide whether to filter small connections
%             WA = obj.g.adjacency;
%             WB = filterSmallEntries(WA, max(abs(WA)), obj.options.weakEdgeThreshold, 'abs', 'max');
%             if (nnz(WB) < 0.9*nnz(WA))
%                 n = size(WB,1);
%                 obj.B = spdiags(sum(WB,2), 0, n, n) - WB;
%             end
            
            % Initialize cached properties
            obj.relaxer         = obj.args.relaxFactory.newInstance(obj);
        end
    end
    
    %======================== ABSTRACT METHODS ========================
    methods (Abstract)
        setP(obj, P)
        % Reconstruct level based on a new interpolation operator P.
        % Applies to non-elimination levels only.
        
        xc = coarseType(obj, x)
        % Restrict the next-finer level function X to this level using the
        % coarse-type operator (X <- T*X).
        
        [b, bStage] = restrict(obj, b)
        % Restrict the next-finer level RHS function B to this level.
        % bStage is a (Q+1)-cell array that stores the original RHS and
        % then the RHS at all Q stages.
        
        x = interpolate(obj, xc, bStage)
        % Interpolate the function X at this level to the next-finer level.
        % Add the affine term that depends on the cell array B of stage
        % RHSs.
    end
    
    %======================== METHODS =================================
    methods     % Hooks
        function setAsCoarsest(obj) %#ok<MANU>
            % Set this level to the coarsest level in the cycle. Compute
            % the number of graph components using a MATLAB library
            % routine. A hook.
        end
    end
    
    methods (Sealed)
        function e = nodalEnergy(obj, x)
            % Return the local nodal energy of x at all nodes. x can be a
            % matrix.
            e = x .* (obj.A * x) - 0.5 * (obj.A * x.^2);
        end
        
        function r = relaxMatrix(obj)
            % Relaxation error propagation matrix, for two-level debugging.
            r = -obj.relaxer.M \ obj.relaxer.N;
        end
        
        function addTv(obj, xNew)
            % Add a test vector to this object's TV list.
            obj.x               = [obj.x xNew];
            %obj.r               = [obj.r obj.A*xNew];
        end
        
        function [x, r] = relax(obj, x, r, b, nu)
            % Perform a relaxation sweep for A*X=B starting with the
            % initial guess X, and return the result.
            [x, r] = obj.relaxer.runWithRhs(x, r, b, nu);
        end
        
        function [x, r] = tvRelax(obj, x, r, nu, lda, k)
            % Perform NU TV-relaxation sweeps (the homogeneous system) on X
            % and return the result.
            %%%[x, r] = obj.relaxer.runHomogeneous(x, r, nu);
            %ob = amg.api.Options;    % object of options
            %lda = ob.lda
            %k = ob.kpower;
            n = length(obj.A);
            adj = diag(diag(obj.A)) - obj.A + lda*speye(n);
            d_inv_sqrt = sum(adj, 2).^-0.5;
            d_inv_sqrt(isinf(d_inv_sqrt)|isnan(d_inv_sqrt)) = 0;
            degree = spdiags(d_inv_sqrt, 0, n, n);
            filter = degree*adj*degree;
            for i=1:k
                x = filter * x;
            end
            r = - obj.A*x;
        end
        
        function setAboveEliminationLevel(obj, relaxFactory, f, c, stage)
            % Set this level to be the next-finer level of an elimination
            % level COARSELEVEL. Sets the relaxer to back-substitution.
            % STAGE contain selimination stage dat astructures.
            obj.relaxer = relaxFactory.newInstance(obj, 'elimination', f, c, stage);
            % If this is an ELIM-ELIM level sequence, clear unncessary
            % operators at the fine level
            s = obj.state;
            if (s.details.isElimination)
                clear obj.g;
                clear obj.A;
            end
        end
        
        function plot(obj, options)
            % TODO: add fine, coarse nodes in the same plot
            figure(500+obj.index);
            plotter = graph.plotter.GraphPlotter(obj.g, 'radius', options.radius);
            plotter.plotNodes('FaceColor', 'k', 'textColor', 'k', 'EdgeColor', 'k', ...
                'label', []);
            plotter.plotEdges('LineWidth', 1);
            %shg;
            save_figure('png', sprintf('%s_level%d.png', obj.name, obj.index));
            %pause;
        end
        
        function g = toGraph(obj)
            % A utility method that converts a Laplacian matrix obj.A to a
            % propert undirected graph.
            adjacency = diag(diag(obj.A)) - obj.A;
            if (~isempty(obj.fineLevel) && ~isempty(obj.fineLevel.g.coord))
                coord = obj.coarseType(obj.fineLevel.g.coord);
            else
                coord = [];
            end
            g = graph.api.Graph.newNamedInstance(obj.g.metadata.name, 'sym-adjacency', adjacency, coord);
        end
    end % public final methods
    
    %======================== GET & SET ===============================
    methods
        function W = get.Wstrong(obj)
            % Compute and cache strong connection adjacency matrix.
            if (isempty(obj.Wstrong))
                obj.Wstrong = obj.g.strongAdjacency(obj.args.options.weakEdgeThreshold);
            end
            W = obj.Wstrong;
        end
    
        function weakEdgePortion = get.weakEdgePortion(obj)
            % Portion of weak edges in graph
            weakEdgePortion = 1 - nnz(obj.Wstrong)/nnz(obj.g.adjacency);
        end
    end
    
    %======================== HOOKS ===================================
    methods (Abstract, Access = protected)
        [g, A] = initOperators(obj, args)
        % initialize graph and operators during construction.
    end
    
    %======================== METHODS =================================
    methods (Access = protected, Sealed)
        function options = parseArgs(obj, type, index, state, relaxFactory, K, varargin) %#ok<MANU>
            % Parse construction options.
            p                   = inputParser;
            p.FunctionName      = 'AbstractLevel';
            p.KeepUnmatched     = false;
            p.StructExpand      = true;
            
            p.addRequired  ('type', @(x)(isa(x,'amg.level.LevelType')));
            p.addRequired  ('index', @isPositiveIntegral);
            p.addRequired  ('state', @(x)(isa(x,'amg.setup.CoarseningState')));
            p.addRequired  ('relaxFactory', @(x)(isa(x,'amg.relax.RelaxFactory')));
            p.addRequired  ('K', @isnumeric);
            p.addParamValue('name', [], @ischar);
            p.addParamValue('A', [], @isnumeric);
            p.addParamValue('Aff', [], @isnumeric);
            p.addParamValue('P', [], @isnumeric);
            p.addParamValue('g', [], @(x)(isa(x,'graph.api.Graph')));
            p.addParamValue('T', [], @isnumeric);
            p.addParamValue('aggregateIndex', [], @isnumeric);
            p.addParamValue('fineLevel', [], @(x)(isa(x,'amg.level.Level')));
            p.addParamValue('options', amg.api.Options, @(x)(isa(x,'amg.api.Options')));
            p.addParamValue('isExactElimination', false, @islogical);
            
            % Elimination level arguments
            p.addParamValue('stage', {}, @iscell);
            p.addParamValue('cycleType', [], @ischar);
            
            % Composite level arguments
            p.addParamValue('subLevels', [], @iscell);  % List of sub-levels (1=finest, end=coarsest)
            
            p.parse(type, index, state, relaxFactory, K, varargin{:});
            options = p.Results;
        end
        
        function g = laplacianToGraph(obj, A, args)
            % A utility method that converts a Laplacian matrix obj.A to a
            % graph g within the Level constructor.
            if (~isempty(args.fineLevel.g.coord))
                coord = obj.coarseType(args.fineLevel.g.coord);
            else
                coord = [];
            end
            g = graph.api.Graph.newNamedInstance(args.name, 'laplacian', A, coord);
        end
    end
end
