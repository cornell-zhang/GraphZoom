classdef (Sealed) LevelElimination < amg.level.AbstractLevel
    %LEVELELIMINATION An exact low-degree node elimination level.
    %   This class holds the data of an elimination level (or a single
    %   sub-level within an elimination level) in the multi-level cycle.
    %
    %   See also: LEVEL, LEVELAGG.
    
    %======================== MEMBERS =================================
    properties (Dependent)
        T           % Coarse type variable matrix (fineLevel -> this)
        P           % Interpolation matrix (this -> fineLevel)
        coord       % Node coordinates (if available in the graph)
    end
    properties (GetAccess = public, SetAccess = private)
        numStages   % # elimination stages
        stage       % A cell array elimination stage information structs
        c           % Coarse-level variables = remaining variables after the entire elimination
        components  % Cached interpolated connected components
    end
    
    %======================== CONSTRUCTORS ============================
    methods
        function obj = LevelElimination(type, index, state, relaxFactory, K, varargin)
            % Initialize an elimination sub-level.
            obj = obj@amg.level.AbstractLevel(type, index, state, relaxFactory, K, varargin{:});
        end
    end
    
    %======================== IMPL: Level =============================
    methods
        function setP(obj, dummy) %#ok
            % Reconstruct level based on a new interpolation operator P.
            % Applies to non-elimination levels only.
            error('MATLAB:Level:setP', 'Setting P of an elimination level is unsupported');
        end
        
        function x = coarseType(obj, x)
            % Restrict the next-finer level function X to this level using
            % the coarse-variable type operator (X = T*XF).
            x = x(obj.c,:);
        end
        
        function [b, bStage] = restrict(obj, b)
            % Restrict the next-finer level RHS function B to this level.
            % bStage is a (Q+1)-cell array that stores the original RHS and
            % then the RHS at all Q stages.
            bStage = cell(obj.numStages,1);
            bStage{1} = b;
            for q = 1:obj.numStages
                s           = obj.stage{q};
                b           = b(s.c,:) + s.PT * b(s.f,:);
                bStage{q+1} = b;
            end
        end
        
        function x = interpolate(obj, xc, bStage)
            % Interpolate the function X at this level to the next-finer
            % level. Add the affine term that depends on the cell array B
            % of stage RHSs.
            K       = size(xc,2);
            for q = obj.numStages:-1:1
                s        = obj.stage{q};
                x        = zeros(s.n, K); % Allocate and set z-variables
                x(s.f,:) = s.P * xc + s.q .* bStage{q}(s.f,:);
                x(s.c,:) = xc;
                xc       = x;
            end
        end
        
        function c = interpolateComponentIndex(obj, c)
            % "Interpolate" (in sparsity pattern sense) the node set C at
            % this level to the next-finer level.
            for q = obj.numStages:-1:1
                Pstage = obj.getInterpolation(q);
                for i = 1:numel(c)
                    [a, dummy]  = find(Pstage(:,c{i})); %#ok
                    clear dummy;
                    % Inlined unique() function so that this code works
                    % for the non-caliber-1 elimination interpolations
                    b = sort(a); b(b((1:end-1)') == b((2:end)')) = [];
                    c{i} = b;
                end
            end
        end
        
        function components = interpolateInternalComponentIndex(obj)
            % Interpolate all z-sets to the next-finer level.
            
            if (~isempty(obj.components))
                components = obj.components;
            else
                % Allocate component index
                total       = sum(cellfun(@(s)(numel(s.z)), obj.stage));
                components = cell(total, 1);
                counter    = 0;
                
                % Loop over elimination stages
                for i = obj.numStages:-1:1
                    s       = obj.stage{i};
                    Pstage  = obj.getInterpolation(i);
                    
                    % Interpolate all next-stage components to this stage
                    for q = 1:counter
                        [a, dummy] = find(Pstage(:,components{q})); %#ok
                        clear dummy;
                        % Inlined unique() function so that this code works
                        % for the non-caliber-1 elimination interpolations
                        b = sort(a); b(b((1:end-1)') == b((2:end)')) = [];
                        components{q} = b;
                    end
                    
                    % Add zero-degree nodes at this stage
                    nz                               = numel(s.z);
                    components(counter+1:counter+nz) = num2cell(s.z);
                    counter                          = counter + nz;
                end
            end
        end
        
        function coord = get.coord(obj)
            % Node coordinates. Recursive call.
            fineCoord = obj.fineLevel.coord;
            if (isempty(fineCoord))
                coord = [];
            else
                coord = fineCoord(obj.c,:);
            end
        end

        function T = get.T(obj) %#ok
            % Coarse type operator.
            error('Unsupported operation: coarse type operator T');
        end
        
        function P = get.P(obj)
            % Interpolation matrix
            P = obj.getInterpolation(obj.numStages);
            for i = obj.numStages-1:-1:1
                P = obj.getInterpolation(i)*P;
            end
        end
        
        function numStages = get.numStages(obj)
            % # elimination stages.
            numStages = numel(obj.stage);
        end
    end
    
    %======================== PRIVATE METHODS =========================
    methods (Access = protected)
        function [g, A] = initOperators(obj, args)
            % Initialize an elimination sub-level using input arguments.
            % Note: graph, A are NOT initialized here.
            
            if (isempty(args.stage))
                error('MATLAB:LevelElimination:initOperators', 'Must pass in an elimination stage cell array');
            end
            
            % Elimination stages objects
            obj.stage   = args.stage;
            
            % Compute fine-level indices of the final coarse set
            c = 1:size(args.A,2); %#ok
            for i = obj.stage(obj.numStages:-1:1)
                s = i{:};
                c = s.c(c); %#ok
            end
            obj.c = c; %#ok

            % Coarse-level operator
            A = args.A;
            g = obj.laplacianToGraph(A, args);
        end
    end
    
    methods (Access = private)
        function Pstage = getInterpolation(obj, stage)
            % Construct the full stage interpolation operator at level
            % STAGE.
            s       = obj.stage{stage};
            nz      = numel(s.z);
            nc      = numel(s.c);
            Pi      = sparse([s.z; s.f; s.c], 1:s.n, ones(s.n,1), s.n, s.n);
            Pstage  = Pi*[sparse(nz,nc); s.P; speye(nc)];
        end
    end
    
end
