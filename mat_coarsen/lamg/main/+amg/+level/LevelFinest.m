classdef (Hidden, Sealed) LevelFinest < amg.level.AbstractLevel
    %FINESTLEVEL The finest level in a multi-level cycle.
    %   This class holds all data and operations pertinent to the finest
    %   level in the multi-level cycle: right-hand-side, residual
    %   computation and single-level processes such as relaxation.
    %
    %   See also: LEVEL, LEVELFACTORY.
    
    %======================== MEMBERS =================================
    properties (Dependent)
        T                       % Coarse variable type
        P                       % Interpolation
        coord                   % Node coordinates (if available in the graph)
    end
    
    %======================== CONSTRUCTORS ============================
    methods
        function obj = LevelFinest(type, index, state, relaxFactory, K, varargin)
            % Initialize the fine level in the multi-level hierarchy from
            % input options.
            obj = obj@amg.level.AbstractLevel(type, index, state, relaxFactory, K, varargin{:});
        end
    end
    
    %======================== IMPL: Level =============================
    methods
        function setP(obj, dummy) %#ok
            % Reconstruct level based on a new interpolation operator P.
            % Applies to non-elimination levels only.
            error('MATLAB:Level:setP', 'Finest level does not have a P');
        end
        
        function x = coarseType(obj, dummy) %#ok
            % Restrict the next-finer level function X to this level using
            % the coarse-type operator (X <- T*X).
            error('MATLAB:Level:coarseType', 'Finest level does not have transfer operators');
        end
        
        function x = restrict(obj, dummy) %#ok
            % Restrict the next-finer level function X to this level.
            error('MATLAB:Level:restrict', 'Finest level does not have transfer operators');
        end
        
        function x = interpolate(obj, dummy) %#ok
            % Interpolate the function X at this level to the next-finer level
            % (x <- P*x).
            error('MATLAB:Level:interpolate', 'Finest level does not have transfer operators');
        end
        
        function c = interpolateComponentIndex(obj, dummy) %#ok
            % "Interpolate" (in sparsity pattern sense) the node set C at
            % this level to the next-finer level.
            error('MATLAB:Level:interpolateComponentIndex', 'Finest level does not have transfer operators');
        end
        
        function T = get.T(obj) %#ok
            % Coarse type operator.
            error('MATLAB:Level:interpolateComponentIndex', 'Finest level does not have transfer operators');
        end
        
        function P = get.P(obj) %#ok
            % Coarse type operator.
            error('MATLAB:Level:interpolateComponentIndex', 'Finest level does not have transfer operators');
        end
        
        function coord = get.coord(obj)
            % Node coordinates (if available in the graph).
            coord = obj.g.coord;
        end
    end
    
    methods (Access = protected)
        function [g, A] = initOperators(obj, args) %#ok<MANU>
            % Initialize graph and operators.
            g = args.g;
            A = args.A;
        end
    end % public methods
end
