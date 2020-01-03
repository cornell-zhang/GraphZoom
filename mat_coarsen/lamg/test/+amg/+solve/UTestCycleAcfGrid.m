classdef (Sealed) UTestCycleAcfGrid < amg.AmgFixture
    %UTestCycleAcfGrid Unit test of cycle ACF batch run for grids.
    %   This class tests the runCycleAcf() function.
    %
    %   See also runCycleAcf.
    
    %=========================== PROPERTIES ==============================
    properties (Constant, GetAccess = protected)
        logger          = core.logging.Logger.getInstance('amg.solve.UTestCycleAcfGrid')
    end
    
    %=========================== CONSTRUCTORS ============================
    methods
        function obj = UTestCycleAcfGrid(name)
            %UTestCycleAcfGrid Constructor
            %   UTestCycleAcfGrid(name) constructs a test case using the
            %   specified name.
            obj = obj@amg.AmgFixture(name);
        end
    end
    
    %=========================== TESTING METHODS =========================
    methods
        function test2dFd(obj) %#ok<MANU>
            % Test increasingly larger 2-D graphs.
            testGrid('fd', 2, 2.^(1:3));
            %testGrid('fd', 2, 2.^(5:9));
        end
        
        function test3dFd(obj) %#ok<MANU>
            % Test increasingly larger 3-D graphs.
            testGrid('fd', 3, round(3*2.^(0:2)));
            %testGrid('fd', 3, round(12.5*2.^(0:3)));
        end
        
        function test2dFe(obj) %#ok<MANU>
            % Test increasingly larger 2-D graphs.
            testGrid('fe', 2, 2.^(1:3));
            %testGrid('fe', 2, 2.^(5:9));
        end
    end
    
    %=========================== PRIVATE METHODS =========================
    methods (Access = private)
    end
end
