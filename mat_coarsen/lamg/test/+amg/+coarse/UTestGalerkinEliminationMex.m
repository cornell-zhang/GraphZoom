classdef (Sealed) UTestGalerkinEliminationMex < amg.AmgFixture
    %UTestGalerkinEliminationMex Unit test of undecided nodes identification
    %using MEX.
    %   This class tests the galerkinElimination.c MEX function correctness
    %   vs. the equivalent MATLAB matrix multplication.
    %
    %   See also: LOWDEGREENODES.
    
    %=========================== PROPERTIES ==============================
    properties (Constant, GetAccess = protected)
        logger = core.logging.Logger.getInstance('amg.coarse.UTestGalerkinEliminationMex')
    end
    
    %=========================== CONSTRUCTORS ============================
    methods
        function obj = UTestGalerkinEliminationMex(name)
            %UTestGalerkinEliminationMex Constructor
            %   UTestGalerkinEliminationMex(name) constructs a test case using
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
            n = 100;
            % Create an SPD matrix
            B = sprandsym(n,1.0); 
            A = B*B'; 
            % An F-C splitting
            f = 1:3:n; 
            c = setdiff(1:n,f);
            % Index array that encodes a running index on F nodes and a
            % running index over C nodes
            index = zeros(1,n); 
            index(c) = 1:numel(c);
            index(f) = 1:numel(f);
            % Mark nodes as F (1) or C (2)
            status = ones(1,n); 
            status(c) = 2; 
            % Transfer operators
            P = -diag(diag(A(f,f)))\A(f,c);
            R = P';
            
            % Matlab version
            B_matlab = A(c,c) + A(c,f)*P;
            
            % Mex version
            B = galerkinElimination(A, R, status, c, index);
            
            assertTrue(norm(B_matlab-B, 1) < 1e-12);
        end
    end
    
    %=========================== PRIVATE METHODS==========================
    methods (Static, Access = private)
    end
end
