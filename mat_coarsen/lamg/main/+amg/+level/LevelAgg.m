classdef (Hidden, Sealed) LevelAgg < amg.level.AbstractLevel
    %FINESTLEVEL A AGG coarse level in a multi-level cycle.
    %   This class holds all data and operations pertinent to a AGG coarse
    %   level in the multi-level cycle: right-hand-side, residual
    %   computation and single-level processes such as relaxation.
    %
    %   See also: LEVEL, LEVELFACTORY.
    
    %======================== MEMBERS =================================
    properties (Constant, GetAccess = private)
        myLogger = core.logging.Logger.getInstance('amg.level.LevelAgg')
        ENERGY_BUILDER_FACTORY = amg.energy.EnergyBuilderFactory
    end
    properties (Dependent)
        T           % Coarse type variable matrix (fineLevel -> this)
        P           % Interpolation matrix (this -> fineLevel)
        coord       % Node coordinates (if available in the graph)
    end
    properties (GetAccess = public, SetAccess = private)
        aggregateIndex  % Map of i->I (for caliber-1 P only)
        R               % Restriction matrix (fineLevel -> this)
    end
    properties (GetAccess = private, SetAccess = private)
		Pprivate 	% Interpolation matrix
        Tprivate    % Coarse type variable matrix (fineLevel -> this)
    end
    
    %======================== CONSTRUCTORS ============================
    methods
        function obj = LevelAgg(type, index, state, relaxFactory, K, varargin)
            % Initialize a AGG level in the multi-level hierarchy from
            % input options.
            obj = obj@amg.level.AbstractLevel(type, index, state, relaxFactory, K, varargin{:});
        end
    end
    
    %======================== IMPL: Level =============================
    methods
        function setP(obj, P)
            % Reconstruct level based on a new interpolation operator P.
            % Applies to non-elimination levels only.
            
            obj.Pprivate = P;
            obj.R = obj.P';
            obj.T = obj.R;
            obj.A = obj.R * obj.fineLevel.A * obj.P;
            
            obj.size                 = size(obj.A, 1);
            adjacency                = diag(diag(obj.A)) - obj.A;
            obj.disconnectedNodes    = find(~sum(adjacency ~= 0, 1));
            obj.hasDisconnectedNodes = ~isempty(obj.disconnectedNodes);
            obj.normalization        = 1.0 ./ full(sum(abs(obj.A),2));
            obj.relaxer              = obj.relaxFactory.newInstance(obj);
        end
        
        function x = coarseType(obj, x)
            % Restrict the next-finer level function X to this level using
            % the coarse-variable type operator (X = T*XF).
            x = obj.Tprivate*x;
        end
        
        function x = restrict(obj, x)
            % Restrict the next-finer level function X to this level.
            x = obj.R*x;
        end
        
        function x = interpolate(obj, x, dummy) %#ok
            % Restrict the function X at this level to the next-finer
            % level.
            x = obj.P*x;
            %x = x(obj.aggregateIndex);  % Hmm - not faster than caliber-1 P sparse MVM
        end
        
        function coord = get.coord(obj)
            coord = obj.getCoord();
        end
        
        function T = get.T(obj)
            % Coarse type operator.
            T = obj.Tprivate;
        end

        function P = get.P(obj)
            % Coarse type operator.
            P = obj.Pprivate;
        end
	end
    
    methods (Access = protected)
        function [g, A] = initOperators(obj, args)
            % Initialize graph and operators. Coarse level, set the
            % interpolation operator to unit interpolation weights with the
            % sparsity pattern of T', and the restriction and coarse
            % operators to the symmetric Galerkin receipe Ac=R*Af*P, R=P'.
            
            if (~isempty(args.P))
                error('Not supported in this impl. Need a non-caliber-1 P corresponding implementation');
%                 % Interpolation operator specified, use P, R=P', T=P'. P
%                 % can be of any caliber.
%                 P       = args.P;
%                 R       = P'; %#ok
%                 T       = R; %#ok
            else
                % T+aggregateIndex must have been specified. Use P=R' R=normalized T, T.
                % Assuming P = caliber-1 (or T = non-overlapping
                % aggregates)
                obj.aggregateIndex = args.aggregateIndex;
                T       = args.T;
                [i,j]   = find(T);
                R       = sparse(i,j,ones(numel(i),1)); %#ok
                P       = R'; %#ok
            end
            
            if (~isempty(args.A))
                % A already passed in
                A = args.A;
            else
                % A = Galerkin coarsening
                %                tStart = tic;
                % About twice faster than matlab's matrix multiplication
                % for large A
                A = galerkinCaliber1(R, args.fineLevel.A, P); %#ok
                [i,j,a] = find(A);
                A = sparse(i,j,a,size(A,1),size(A,2));
                %                tMex = toc(tStart);
                %                 tStart = tic; A  = R * args.fineLevel.A *
                %                 P; %#ok t = toc(tStart); n =
                %                 args.fineLevel.g.numNodes; m =
                %                 args.fineLevel.g.numEdges;
                %                 fprintf('Galerkin: n=%8d m=%9d, time mat
                %                 = %.2e, time mex = %.2e\n', ...
                %                     n, m, t/m, tMex/m);
            end
            
            % TV initial guess = restricted fine level TV. Also a useful
            % setting for energy correction.
            obj.Tprivate    = T;
            obj.R           = R; %#ok
            obj.Pprivate    = P;
            g               = obj.laplacianToGraph(A, args);
        end
        
        function [A, rhsMu] = energyCorrection(obj, args)
            % Improve coarse level operator using energy correction.
            energyBuilder = amg.level.LevelAgg.ENERGY_BUILDER_FACTORY.newInstance(...
                args.options.energyCorrectionType, args.fineLevel, obj, args.options);
            [A, rhsMu]  = energyBuilder.buildEnergy();

            % Debugging printouts
            if (obj.myLogger.traceEnabled)
                energyBuilder.printCurrentEnergies();
            end
        end
    end % protected methods
    
    methods (Access = private)
        function coord = getCoord(obj)
            % Node coordinates (if available in the graph).
            fineCoord = obj.fineLevel.coord;
            if (isempty(fineCoord))
                coord = [];
            else
                coord = obj.Tprivate * fineCoord;
            end
        end
    end        
end
