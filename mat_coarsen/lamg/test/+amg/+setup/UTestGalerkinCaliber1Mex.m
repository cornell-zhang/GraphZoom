classdef (Sealed) UTestGalerkinCaliber1Mex < amg.AmgFixture
    %UTestGalerkinCaliber1Mex Unit test of the caliber-1 Galerkin
    %computation MEX implementation.
    %   This class tests the galerkinCaliber1.c MEX function correctness
    %   vs. the equivalent MATLAB matrix multplication.
    %
    %   See also: LOWDEGREENODES.
    
    %=========================== PROPERTIES ==============================
    properties (Constant, GetAccess = protected)
        logger = core.logging.Logger.getInstance('amg.coarse.UTestGalerkinCaliber1Mex')
    end
    
    %=========================== CONSTRUCTORS ============================
    methods
        function obj = UTestGalerkinCaliber1Mex(name)
            %UTestGalerkinCaliber1Mex Constructor
            %   UTestGalerkinCaliber1Mex(name) constructs a test case using
            %   the specified name.
            obj = obj@amg.AmgFixture(name);
        end
    end
    
    %=========================== TESTING METHODS =========================
    methods
        function testMexCorrectness(obj) %#ok<MANU>
            % Test that MEX code and slower MATLAB code produce the same
            % result for a 1-D Laplacian problem.
            
            n = 10; 
            nc = 5; 
            A = sprandsym(n, 0.3); 
            i = 1:n; I = randi(nc,n,1); 
            I(1:nc) = (1:nc); 
            R = sparse(I,i,ones(numel(i),1)); 
            P = R'; 
            
            % Matlab version
            B = R*A*P;
            
            % Mex version
            C = galerkinCaliber1(R,A,P);
            assertEqual(B, C);
        end
    end
    
    %=========================== PRIVATE METHODS==========================
    methods (Static, Access = private)
    end
end
