classdef (Sealed) Problem < handle
    %LEVEL A graph linear system.
    %   This immutable class describes a computational undirected graph
    %   problem of the form A*X=B.
    %
    %   This class acts as an adapter of a GRAPH instance. If the graph's
    %   adjacency matrix G has large positive off-diagonal elements (G(I,J)
    %   > 0.1 * SQRT(SUM(G(I,:))*SUM(G(:,J))), the elementwise absolute
    %   value of G is stored in the graph field of this class, and is used
    %   to build A. That's because we currently target Laplacian linear
    %   systems.
    %
    %   See also: PROBLEMESETUP, LEVEL, GRAPH.
    
    %======================== MEMBERS =================================
    properties (GetAccess = public, SetAccess = private)
        A               % Left-hand-side matrix
        b               % Right-hand-side vector/matrix
        g               % Graph instance
        coord           % A-row coordinates, if available
    end
    
    %======================== CONSTRUCTORS ============================
    methods
        function obj = Problem(A, b, varargin)
            % Initialize a level for the linear problem A*x=b. A = g's
            % symmetric adjacency matrix where g = undirected weighted
            % graph.
            obj.A = A;
            obj.b = b;
            if (numel(varargin) >= 1)
                obj.g = varargin{1};
            end
            if (numel(varargin) >= 2)
                obj.coord = varargin{2};
            end
        end
    end
    
    %======================== METHODS =================================
    methods
        function r = residual(obj, x)
            % Compute the residual B-A*X for a function X at this level.
            numVectors = size(x,2);
            if (numVectors == 1)
                r = obj.b - obj.A*x;
            else
                % x is a matrix, compute the residual vector of each column
                r = repmat(obj.b, [1 numVectors]) - obj.A*x;
            end
        end
    end
end
