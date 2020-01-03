classdef (Sealed) UTestGraph < graph.GraphFixture
    %UTestGraph Test basic graph methods.
    %   This class includes unit tests of Class Graph and its methods.
    
    %=========================== PROPERTIES ==============================
    properties (Constant, GetAccess = protected)
        logger = core.logging.Logger.getInstance('graph.api.UTestGraph')
        
        % A simple example graph - data
        EDGE_DATA   = [[1 2 3];[1 3 3];[2 3 1];[2 4 2];[3 4 4]];
        % Incidence matrix
        N           = [[1 -1 0 0]; [1 0 -1 0]; [0 1 -1 0]; [0 1 0 -1]; [0 0 1 -1]];
        % Verex location
        LOCATION    = [[0 0]; [1 1]; [1 -1]; [2 0]];
    end
    properties (GetAccess = protected)
        % A simple example graph
        simpleGraph
    end
    
    %=========================== CONSTRUCTORS ============================
    methods
        function obj = UTestGraph(name)
            %UTestGraph Constructor
            %   UTestGraph(name) constructs a test case using
            %   the specified name.
            obj = obj@graph.GraphFixture(name);
        end
    end
    
    %=========================== SETUP METHODS ===========================
    methods
        function setUp(obj)
            %setUp Simple test fixture setup.
            setUp@graph.GraphFixture(obj);
            obj.simpleGraph = graph.api.Graph.newNamedInstance(...
                'simple', graph.api.GraphType.DIRECTED, ...
                graph.api.UTestGraph.EDGE_DATA, ...
                graph.api.UTestGraph.LOCATION);
        end
        
        function tearDown(obj)
            %tearDown Simple test fixture tear-down.
            obj.simpleGraph = [];
        end
        
    end
    
    %=========================== TESTING METHODS =========================
    methods
        function testGlobalVarExists(obj)
            % Test that global variables have been correctly loaded into
            % the workspace.
            global GLOBAL_VARS
            assertTrue(~isempty(GLOBAL_VARS.home_dir));
        end
        
        function testIncidence(obj)
            % Test the graph incidence matrix against a known reference.
            assertEqual(full(obj.simpleGraph.incidence), graph.api.UTestGraph.N);
        end
        
        function testLaplacian(obj)
            % Test the graph Laplacian matrix against a known reference.
            g = obj.simpleGraph;
            n = g.incidence;
            w = g.weightMatrix;
            L = n'*w*n;
            assertEqual(g.laplacian, L);
        end
        
        function testSun(obj)
            % Test the graph Laplacian matrix of a sun graph (a central
            % node connected to all others).
            
            % Central node = 1. Other nodes = 2..n.
            n           = 10;
            edgeData    = [ones(n-1,1) (2:n)' ones(n-1,1)];
            g           = graph.api.Graph.newNamedInstance(...
                'sun', graph.api.GraphType.UNDIRECTED, edgeData);
            
            a = full(g.laplacian);
            d = sort(eig(a));
            assertElementsAlmostEqual(d, [0; ones(n-2,1); n], 'absolute', 1e-8);
            
            % GS is a direct solver
            obj.assertGsAcfAlmostEqual(a, 0, 'absolute', 1e-8);
            % over-relaxation Jacobi converges fast, too
            obj.assertWeightedJacobiAcfAlmostEqual(a, 3/2, 1/3, 'relative', 1e-8);
        end
        
        function testFullyConnected(obj)
            % Test the graph Laplacian matrix of a fully connected graph (a central
            % node connected to all others).
            
            % Central node = 1. Other nodes = 2..n.
            n           = 10;
            edge        = harmonics(2,n)+1;
            edge(edge(:,1) >= edge(:,2),:) = [];
            edgeData    = [edge ones(size(edge,1), 1)];
            g           = graph.api.Graph.newNamedInstance(...
                'full', graph.api.GraphType.UNDIRECTED, edgeData);
            
            a = full(g.laplacian);
            d = sort(eig(a));
            assertElementsAlmostEqual(d, [0; n*ones(n-1,1)], 'absolute', 1e-8);
            
            % GS is not a direct solver but fast
            obj.assertGsAcfAlmostEqual(a, 1/8, 'relative', 1e-1);
            % omega-J with a slightly overrelaxation is a direct solver
            obj.assertWeightedJacobiAcfAlmostEqual(a, n/(n-1), 0, 'relative', 1e-8);
        end
        
    end
    
    %=========================== PRIVATE METHODS =========================
    methods (Access = private)
        function assertGsAcfAlmostEqual(obj, a, expected, tolType, tol)
            % Check the GS ACF.
            obj.assertRelaxAcfAlmostEqual(a, tril(a), expected, tolType, tol); % Filter the constant vector to get the true ACF
        end
        
        function assertWeightedJacobiAcfAlmostEqual(obj, a, omega, expected, tolType, tol)
            % Check the  omega-J  ACF.
            % omega-J with a slightly underrelaxation is a direct solver
            obj.assertRelaxAcfAlmostEqual(a, omega*diag(diag(a)), expected, tolType, tol); % Filter the constant vector to get the true ACF
        end
        
        function assertRelaxAcfAlmostEqual(obj, a, m, expected, tolType, tol)
            % Check the ACF of the relaxation with splitting matrix M for
            % A*x=b. A is assumed to have zero-row sums.
            n = size(a,1);
            lam = sort(abs(eig(eye(n) - m\a)));
            assertElementsAlmostEqual(lam(end-1), expected, tolType, tol); % Filter the constant vector to get the true ACF
        end
    end
    
end
