classdef (Hidden) AbstractLevel < amg.level.Level
    %LEVEL A single level in the multi-level cycle.
    %   This class holds all data and operations pertinent to a single
    %   level in the multi-level cycle: right-hand-side, residual
    %   computation and single-level processes such as relaxation.
    
    %======================== MEMBERS =================================
    properties (Constant, GetAccess = private)
        logger = core.logging.Logger.getInstance('amg.level.AbstractLevel')
    end
    
    properties (Dependent)
        zeroMatrix              % True iff A = 0
    end
    properties (GetAccess = public, SetAccess = private)
        % Level properties
        isElimination                   % Flag: is this level an elimination level or not
        isExactElimination = false      % Flag: is this an exact elimination level or an approximate elimination that requires defect-correction iterations at the next finer level
        
        % Energy correction
        rhsMu                           % RHS correction factor, if flat energy correction is used
    end
    
    %======================== CONSTRUCTORS ============================
    methods (Access = protected)
        function obj = AbstractLevel(type, index, state, relaxFactory, K, varargin)
            % Initialize a level for the linear problem A*x=0 from input
            % options.
            obj = obj@amg.level.Level(type, index, state, relaxFactory, K, varargin{:});
            obj.isElimination = state.details.isElimination;
            if (obj.isElimination)
                options = obj.parseArgs(type, index, state, relaxFactory, K, varargin{:});
                obj.isExactElimination = options.isExactElimination;
            end
            
            % Improve coarse level operator using energy correction
            [obj.A, obj.rhsMu] = obj.energyCorrection(obj.args);
        end
    end
    
    %======================== ABSTRACT METHODS ========================
    methods (Abstract)
        setP(obj, P)
        % Reconstruct level based on a new interpolation operator P.
        % Applies to non-elimination levels only.
    end
        
    %======================== METHODS =================================
    methods (Sealed)
        function y = componentSpan(obj)
            % Return an MxN matrix whose columns span the null-space of A.
            % Assuming a singly-connected graph.
            %y = spones(ones(obj.numNodes,1));
            n = obj.g.numNodes;
            u = ones(n,1);
            y = sparse(1:n, u, u, n, 1);
        end
        
        function setAsCoarsest(obj) %#ok<MANU>
            % Set this level to the coarsest level in the cycle. Compute
            % the number of graph components using a MATLAB library
            % routine.
            %             [s, dummy1, y] = graphComponents(obj.A);
            %             obj.numComponents = s;
            %             obj.componentIndex = y;
        end
        
        function detachNode(obj, s)
            % Useful for debugging. Detach s from its aggregate. Size of
            % aggregate containing s
            [k, dummy] = find(obj.R(:,s)); %#ok
            clear dummy;
            aggregateSize = sum(obj.R(k,:),2);
            associates = find(aggregateSize > 1);
            
            if (~isempty(associates))
                % There are some non-seed nodes in s to be detached
                [i,j,a] = find(obj.R);
                nz = [i j a];
                
                % Change s's aggregate entry to s (so that s is now its own
                % aggregate)
                m = size(obj.R,1);
                nz(s(associates),1) = m+(1:numel(associates))';
                obj.setP(spconvert(nz)');
            end
        end
    end % public final methods

    %======================== GET & SET ===============================
    methods
        function zeroMatrix = get.zeroMatrix(obj)
            % Return true iff A = 0.
            zeroMatrix = (nnz(obj.A) == 0);
        end
    end

    %======================== HOOKS ===================================
    methods (Access = protected)
        function [A, rhsMu] = energyCorrection(obj, args) %#ok
            % Improve coarse level operator using energy correction. By
            % default, no correction is applied.
            A       = obj.A;
            rhsMu   = [];
        end
    end
end
