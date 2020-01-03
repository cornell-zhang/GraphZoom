classdef (Sealed) UTestFilterSmallEntriesMex < amg.AmgFixture
    %UTestFilterSmallEntriesMex Unit test of the filterSmallMatrix MEX
    %implementation.
    %   This class tests the filterSmallMatrix.c MEX function correctness
    %   vs. the MATLAB equivalent filterSmallMatrixSym().
    %
    %   See also: LOWDEGREENODES.
    
    %=========================== PROPERTIES ==============================
    properties (Constant, GetAccess = protected)
        logger = core.logging.Logger.getInstance('amg.coarse.UTestFilterSmallEntriesMex')
    end
    
    %=========================== CONSTRUCTORS ============================
    methods
        function obj = UTestFilterSmallEntriesMex(name)
            %UTestFilterSmallEntriesMex Constructor
            %   UTestFilterSmallEntriesMex(name) constructs a test case
            %   using the specified name.
            obj = obj@amg.AmgFixture(name);
        end
    end
    
    %=========================== TESTING METHODS =========================
    methods
        function testAdjacencyFilterCorrectness(obj)
            % Test that MEX code and slower MATLAB code produce the same
            % result for filtering an adjacency matrix.
            
            n = 10; %100;
            delta = 0.1;
            valueType = 'abs';
            boundType = 'min';
            for density = 0.1:0.1:1.0
                % Input data
                A = sprandsym(n, density);
                A = 0.5*(A+A');         % Our MATLAB version only supports symmetric matrices
                b = max(abs(A))+eps;    % Bound vector. Must be strictly positive.
                A = A - diag(diag(A)) ; % A must NOT have a diagonal
                
                %----------------------------------------
                % Run m-code (slower but reliable)
                %----------------------------------------
                tStart = tic;
                Cmatlab = filterSmallEntriesSym(A, b, delta, valueType, boundType);
                tMatlab = toc(tStart);
                
                %----------------------------------------
                % Run mex code
                %----------------------------------------
                tStart = tic;
                Cmex = filterSmallEntries(A, b, delta, valueType, boundType);
                tMex = toc(tStart);
                
                assertElementsAlmostEqual(Cmex, Cmatlab, 'relative', 1e-13);
                if (obj.logger.infoEnabled)
                    obj.logger.info('mex=%f sec, matlab=%f sec, speedup=%f\n', ...
                        tMex, tMatlab, tMatlab/tMex);
                end
            end
        end
        
        function testAffinityFilterCorrectness(obj)
            % Test that MEX code and slower MATLAB code produce the same
            % result for filtering an affinity matrix.
            
            n = 100;
            delta = 0.1;
            valueType = 'value';
            boundType = 'max';
            for density = 0.1:0.1:1.0
                % Input data
                A = sprandsym(n, density);
                A = 0.5*(A+A');         % Our MATLAB version only supports symmetric matrices
                b = max(abs(A))+eps;    % Bound vector. Must be strictly positive.
                A = A - diag(diag(A)) ; % A must NOT have a diagonal
                
                %----------------------------------------
                % Run m-code (slower but reliable)
                %----------------------------------------
                tStart = tic;
                Cmatlab = filterSmallEntriesSym(A, b, delta, valueType, boundType);
                tMatlab = toc(tStart);
                
                %----------------------------------------
                % Run mex code
                %----------------------------------------
                tStart = tic;
                Cmex = filterSmallEntries(A, b, delta, valueType, boundType);
                tMex = toc(tStart);
                
                assertElementsAlmostEqual(Cmex, Cmatlab, 'relative', 1e-13);
                if (obj.logger.infoEnabled)
                    obj.logger.info('mex=%f sec, matlab=%f sec, speedup=%f\n', ...
                        tMex, tMatlab, tMatlab/tMex);
                end
            end
        end
    end
    
    %=========================== PRIVATE METHODS==========================
    methods (Static, Access = private)
    end
end
