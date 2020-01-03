classdef (Sealed) UTestAffinityMatrixMex < amg.AmgFixture
    %UTestAffinityMatrixMex Unit test of the affinitymatrix MEX
    %implementation.
    %   This class tests the affinitymatrix.c MEX function correctness vs.
    %   the MATLAB equivalent affinityMatrix().
    %
    %   See also: LOWDEGREENODES.
    
    %=========================== PROPERTIES ==============================
    properties (Constant, GetAccess = protected)
        logger = core.logging.Logger.getInstance('amg.coarse.UTestAffinityMatrixMex')
    end
    
    %=========================== CONSTRUCTORS ============================
    methods
        function obj = UTestAffinityMatrixMex(name)
            %UTestAffinityMatrixMex Constructor
            %   UTestAffinityMatrixMex(name) constructs a test case using
            %   the specified name.
            obj = obj@amg.AmgFixture(name);
        end
    end
    
    %=========================== TESTING METHODS =========================
    methods
        function testMexCorrectness(obj)
            % Test that MEX code and slower MATLAB code produce the same
            % result for a 1-D Laplacian problem.
            
            randomSeed = 10;
            n = 10;
            K = 4;

            % Set random state for deterministic results
            s = RandStream('mt19937ar','Seed', randomSeed);
            RandStream.setGlobalStream(s);
            
            % Input data
            W = sprandsym(n, 0.3);
            x = rand(n, K);
            
            %----------------------------------------
            % Run m-code (slower but reliable)
            %----------------------------------------
            tStart = tic;
            Cmatlab = affinityMatrix_matlab(W, x);
            tMatlab = toc(tStart);
            
            %----------------------------------------
            % Run mex code
            %----------------------------------------
            %disp('=================================================================');
            tStart = tic;
            Cmex = affinitymatrix(W, x);
            tMex = toc(tStart);

            assertElementsAlmostEqual(Cmex, Cmatlab, 'relative', 1e-15);
            if (obj.logger.infoEnabled)
                obj.logger.info('Affinity matrix: matlab=%f sec speedup=%f\n', ...
                    tMex, tMatlab, tMatlab/tMex);
            end
        end
    end
    
    %=========================== PRIVATE METHODS==========================
    methods (Static, Access = private)
    end
end
