classdef (Sealed) UTestConnectedComponents < amg.AmgFixture
    %UTestElimination Unit tests of graph connected component computation.
    %   Requires the Bioinformatics Toolbox function GRAPHCONNCOMP.
    
    %=========================== PROPERTIES ==============================
    properties (Constant, GetAccess = protected)
        logger          = core.logging.Logger.getInstance('amg.solve.UTestConnectedComponents')
    end
    
    %=========================== CONSTRUCTORS ============================
    methods
        function obj = UTestConnectedComponents(name)
            %UTestConnectedComponents Constructor
            %   UTestConnectedComponents(name) constructs a test case using
            %   the specified name.
            obj = obj@amg.AmgFixture(name);
        end
    end
    
    %=========================== SETUP METHODS ===========================
    methods
        function setUp(obj)
            setUp@amg.AmgFixture(obj);
        end
    end
    
    %=========================== TESTING METHODS =========================
    methods
        function testConnectedComponents(obj)
            % Test eliminating zero-degree nodes.
            
            % Small singly-connected graphs
            obj.graphConnectedComponents('lap/uf/Pajek/Sandi_authors');
            
            % Small multi-connected graphs - inactive, we no longer support
            % multi-connected graphs and require pre-processing to break
            % them into their components.
            %obj.graphConnectedComponents('lap/walshaw/coloring/huck');
            %obj.graphConnectedComponents('lap/walshaw/coloring/miles250');
        end
    end
    
    %=========================== PRIVATE METHODS==========================
    methods (Access = private)
        function graphConnectedComponents(obj, key) %#ok<MANU>
            % Test that our algorithm's result coincides with the MATLAB
            % function results for a single graph.
            problem = AmgTestUtil.loadProblem(key);
            C = components(problem.g.adjacency);
            S = max(C);
            [s, c, y] = graphComponents(problem.A);
            assertEqual(s, S);
            assertEqual(c, C);
            for index = 1:s
                assertEqual(y{index}, find(c == index)');
            end
        end
    end
end
