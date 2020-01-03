classdef Solver < handle
    %SOLVER A graph Laplacian linear solver.
    %   This class is an abstraction for solvers of the linear problem
    %   A*X=B, where A is a an NxN graph Laplacian graph and B is an NxM
    %   matrix (usually M=1, but could be arbitrary).
    %
    %   Separate methods are available for the setup and solve phases of
    %   the solver.
    %
    %   See also: OPTIONS, GRAPH, CYCLES, PROBLEM, MULTILEVELSETUP.
    
    
    %=========================== PROPERTIES ==============================
    properties (GetAccess = public, SetAccess = private)
        contextKey    % Key to save setup under, if specified
        iterative     % Is this solver iterative (true) or direct (false)                  
    end
    
    %======================== CONSTRUCTORS ============================
    methods (Access = protected)
        function obj = Solver(contextKey, iterative)
            % Constructor.
            obj.contextKey 	= contextKey;
            obj.iterative   = iterative;
        end
    end
    
    %======================== METHODS =================================
    methods (Sealed)
        function setup = setup(obj, dataType, data)
            %SETUP LAMG setup phase: construct a multilevel hierarchy.
            %OBJ.SETUP('problem', DATA) assumes that DATA is a linear
            %problem to be solved.
            %OBJ.SETUP('adjacency', DATA) assumes DATA is a symmetric
            %graph adjacency matrix matrix. OBJ.SETUP('graph', DATA)
            %assumes DATA is a graph.api.Graph, in which case
            %DATA.laplacian is used. OBJ.SETUP('laplacian', DATA) assumes
            %DATA is the graph Laplacian.
            
            % Convert from every input type except a problem to a graph
            switch (dataType)
                case 'problem',
                    g = data;
                case 'graph',
                    g = data;
                case 'adjacency',
                    g = Graphs.fromAdjacency(data);
                case {'laplacian'}
                    g = graph.api.Graph.newNamedInstance('graph', dataType, data, []);
                otherwise,
                    g = [];
            end
            switch (dataType)
                case 'problem',
                    problem = data;
                case {'sdd'}
                    problem = lin.api.Problem(data, [], []);
                otherwise,
                    if (isempty(g))
                        error('Unrecognized input data type %s', dataType);
                    else
                        problem = lin.api.Problem(g.laplacian, [], g);
                    end
            end
            
            setup = obj.doSetup(problem);
        end
    end
    
    methods (Abstract)
        fieldNames = detailsFieldNames(obj)
        % Return a cell array of solver public output fields returned in
        % the DETAILS argument of SOLVE. These may be all or a subset of
        % DETAILS' field list.
        
        [x, success, errorNormHistory, details] = solve(obj, setup, b, varargin)
        % Perform linear solve on A*x=B using the setup object SETUP
        % construcated for A. VARARGIN contains custom solve options.
        % Return the approximate solution X and statistics in the struct
        % DETAILS. SUCCESS = boolean success code. ERRORNORMHISTORY =
        % optional error norm history (for iterative solvers only).
        % VARARGIN contains solve arguments that potentially override the
        % default solver options.
    end
    
    %======================== PRIVATE METHODS =========================
    methods (Abstract, Access = protected)
        setup = doSetup(obj, problem)
        % Perform solver setup phase on the object PROBLEM
        % representing the linear problem A*x=b.
    end
end
