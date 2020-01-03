classdef (Sealed) UTestUndecidedNodesMex < amg.AmgFixture
    %UTestUndecidedNodesMex Unit test of undecided nodes identification
    %using MEX.
    %   This class tests the galerkinCaliber1.c MEX function correctness
    %   vs. the equivalent MATLAB matrix multplication.
    %
    %   See also: LOWDEGREENODES.
    
    %=========================== PROPERTIES ==============================
    properties (Constant, GetAccess = protected)
        logger = core.logging.Logger.getInstance('amg.coarse.UTestUndecidedNodesMex')
    end
    
    %=========================== CONSTRUCTORS ============================
    methods
        function obj = UTestUndecidedNodesMex(name)
            %UTestUndecidedNodesMex Constructor
            %   UTestUndecidedNodesMex(name) constructs a test case using
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
            n = 1000;
            numBins = 10;
            A = abs(sprandsym(n, 0.01));
            candidate = 2:n/10+1;
            i = 1:n;
            isOpen = (i >= n/10) & (i < n/2);
            
            % Matlab version
            undecided_matlab = candidate(sum(spones(A(isOpen,candidate))) > 0);
            Amax_matlab = max(A(isOpen,undecided_matlab), [], 1);
            bins_matlab = cellfun(@(x)(undecided_matlab(x)), binsort(Amax_matlab, numBins), ...
                'UniformOutput', false);
            
            % Mex version
            bins = undecidedNodes(A, candidate, isOpen, numBins);
            
            assertEqual(bins, bins_matlab);
        end
        
        function testEmptyUndecidedSet(obj) %#ok<MANU>
            % Test that MEX code and slower MATLAB code produce the same
            % result for a 1-D Laplacian problem.
            
            % Set up test problem simulating candidates and open nodes
            setRandomSeed(1);
            n = 1000;
            numBins = 10;
            A = abs(sprandsym(n, 0.01));
            candidate = [];
            i = 1:n;
            isOpen = (i >= n/10) & (i < n/2);
            
            % Mex version
            bins = undecidedNodes(A, candidate, isOpen, numBins);
            assertEqual(bins, {});
            assertTrue(isempty(bins));
        end
    end
    
    %=========================== PRIVATE METHODS==========================
    methods (Static, Access = private)
    end
end
