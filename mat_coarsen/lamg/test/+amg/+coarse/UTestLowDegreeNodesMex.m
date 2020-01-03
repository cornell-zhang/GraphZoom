classdef (Sealed) UTestLowDegreeNodesMex < amg.AmgFixture
    %UTestLowDegreeNodesMex Unit test of the lowDegreNodes MEX
    %implementation.
    %   This class tests the lowdegreesweep.c MEX function correctness
    %   within the lowDegreeNodes() method.
    %
    %   See also: LOWDEGREENODES.
    
    %=========================== PROPERTIES ==============================
    properties (Constant, GetAccess = protected)
        logger = core.logging.Logger.getInstance('amg.coarse.UTestLowDegreeNodesMex')
    end
    
    %=========================== CONSTRUCTORS ============================
    methods
        function obj = UTestLowDegreeNodesMex(name)
            %UTestLowDegreeNodesMex Constructor
            %   UTestLowDegreeNodesMex(name) constructs a test case using
            %   the specified name.
            obj = obj@amg.AmgFixture(name);
        end
    end
    
    %=========================== TESTING METHODS =========================
    methods
        function testMexCorrectness(obj)
            % Test that MEX code and slower MATLAB code produce the same
            % result for a 1-D Laplacian problem.
            
            for m = [10 20 40 80], % Problem size
                g = Graphs.grid('fd', [m m]);
                A = g.adjacency;
                for maxDegree = 3:4
                    % Run mex code
                    tStart = tic;
                    [fFast, cFast] = lowDegreeNodes(A, g.degree, maxDegree);
                    tMex = toc(tStart);
                    
                    % Run m-code (slower but reliable)
                    tStart = tic;
                    [dummy, f, c] = lowDegreeNodes_matlab(A, g.degree, maxDegree); %#ok
                    tMatlab = toc(tStart);
                    
                    assertEqual(f, fFast);
                    assertEqual(c, cFast);
                    if (obj.logger.infoEnabled)
                        obj.logger.info('maxDegree=%d mex=%f sec, matlab=%f sec speedup=%f\n', ...
                            maxDegree, tMex, tMatlab, tMatlab/tMex);
                    end
                end
            end
        end
    end
    
    %=========================== PRIVATE METHODS==========================
    methods (Static, Access = private)
    end
end
