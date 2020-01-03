classdef (Sealed) UTestEliminationOperatorsMex < amg.AmgFixture
    %UTestEliminationOperatorsMex Unit test of undecided nodes identification
    %using MEX.
    %   This class tests the eliminationOperators.c MEX function correctness
    %   vs. the equivalent MATLAB matrix multplication.
    %
    %   See also: LOWDEGREENODES.
    
    %=========================== PROPERTIES ==============================
    properties (Constant, GetAccess = protected)
        logger = core.logging.Logger.getInstance('amg.coarse.UTestEliminationOperatorsMex')
    end
    
    %=========================== CONSTRUCTORS ============================
    methods
        function obj = UTestEliminationOperatorsMex(name)
            %UTestEliminationOperatorsMex Constructor
            %   UTestEliminationOperatorsMex(name) constructs a test case using
            %   the specified name.
            obj = obj@amg.AmgFixture(name);
        end
    end
    
    %=========================== TESTING METHODS =========================
    methods
        function testMexCorrectness(obj) %#ok<MANU>
            % Test that MEX code and slower MATLAB code produce the same
            % result for a 1-D Laplacian problem.
            
            % Set up test problem simulating candidates and open nodes
            setRandomSeed(1);
            n = 100;
            setRandomSeed(1); 
            % Create an SPD matrix
            B = sprandsym(n,1.0); 
            A = B*B'; 
            % An F-C splitting
            f = 1:2:n; 
            c = setdiff(1:n,f);
            c_index = zeros(1,n); 
            c_index(c) = 1:numel(c);
            
            % Matlab version
            P = -diag(diag(A(f,f)))\A(f,c); 
            R = P';
            q = 1./diag(A(f,f)); 
            
            % Mex version
            [R1, q1] = eliminationOperators(A, f, c_index);
            
            assertTrue(norm(R1-R, 1) < 1e-14);
            assertTrue(norm(q1-q) < 1e-14);
        end
    end
    
    %=========================== PRIVATE METHODS==========================
    methods (Static, Access = private)
    end
end
