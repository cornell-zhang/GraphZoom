classdef (Sealed) UTestMedianColMex < amg.AmgFixture
    %UTestMedianColMex Unit test of the medianCol MEX implementation.
    %   This class tests the medianCol.c MEX function correctness vs. the
    %   MATLAB equivalent medianColSym().
    %
    %   See also: LOWDEGREENODES.
    
    %=========================== PROPERTIES ==============================
    properties (Constant, GetAccess = protected)
        logger = core.logging.Logger.getInstance('amg.coarse.UTestMedianColMex')
    end
    
    %=========================== CONSTRUCTORS ============================
    methods
        function obj = UTestMedianColMex(name)
            %UTestMedianColMex Constructor
            %   UTestMedianColMex(name) constructs a test case using the
            %   specified name.
            obj = obj@amg.AmgFixture(name);
        end
    end
    
    %=========================== TESTING METHODS =========================
    methods
        function testAdjacencyFilterCorrectness(obj)
            % Test that MEX code and slower MATLAB code produce the same
            % result for filtering an adjacency matrix.
            
            n = 100;
            for i = 1:10 % Random experiments
                A = sprandsym(n,0.3);
                A(:,5) = 0; % Zero-out an entire column
                x = randi(10,n,1);
                
                %----------------------------------------
                % Run m-code (slower but reliable)
                %----------------------------------------
                tStart = tic;
                yMatlab = amg.coarse.UTestMedianColMex.medianCol_matlab(A, x);
                tMatlab = toc(tStart);
                
                %----------------------------------------
                % Run mex code
                %----------------------------------------
                tStart = tic;
                yMex = medianCol(A, x);
                tMex = toc(tStart);
                
                assertElementsAlmostEqual(yMex, yMatlab, 'relative', 1e-13);
                if (obj.logger.infoEnabled)
                    obj.logger.info('mex=%f sec, matlab=%f sec, speedup=%f\n', ...
                        tMex, tMatlab, tMatlab/tMex);
                end
            end
        end
    end
    
    %=========================== PRIVATE METHODS==========================
    methods (Static, Access = private)
        function y = medianCol_matlab(A, x)
            % Slow MATLAB implementation of medianCol().
            n = size(A,1);
            y = zeros(n,1);
            for j = 1:n
                [i, dummy] = find(A(:,j));
                clear dummy;
                if (~isempty(i))
                    z = sort(x(i));
                    y(j) = z(floor(numel(i)/2)+1);
                end
            end
        end
    end
end
