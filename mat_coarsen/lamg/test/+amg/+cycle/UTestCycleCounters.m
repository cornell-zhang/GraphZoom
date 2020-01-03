classdef (Sealed) UTestCycleCounters < amg.AmgFixture
    %UTestCycleCounters Unit test cycle index logic.
    %   Test that the level visitation counters lead to a correct
    %   visitation pattern in the multigrid cycle.
    
    %=========================== PROPERTIES ==============================
    properties (Constant, GetAccess = protected)
        logger          = core.logging.Logger.getInstance('amg.cycle.UTestCycleCounters')
    end
    
    %=========================== CONSTRUCTORS ============================
    methods
        function obj = UTestCycleCounters(name)
            %UTestCycleCounters Constructor
            %   UTestCycleCounters(name) constructs a test case using the
            %   specified name.
            obj = obj@amg.AmgFixture(name);
        end
    end
    
    %=========================== SETUP METHODS ===========================
    methods
        function setUp(obj)
            setUp@amg.AmgFixture(obj);
            if (obj.logger.infoEnabled)
                obj.logger.info('\n');
            end
        end
    end
    
    %=========================== TESTING METHODS =========================
    methods
        function testCycleCountersFewLevelsIntegerCycleIndex(obj)
            % Test that cycle level counters are correctly used for a
            % gamma-cycle logic.
            
            for g = [1 2]
                for numLevels = 3
                    if (obj.logger.traceEnabled)
                        obj.logger.trace('### Cycle, #levels=%d ###\n', numLevels);
                    end
                    % Exact behavior for integer cycle index
                    amg.cycle.UTestCycleCounters.cycleIndexTest(numLevels, g, 0.6);
                end
            end
        end
        
        function testCycleCounters(obj)
            % Test that cycle level counters are correctly used for a
            % gamma-cycle logic. (many-level test)
            
            for g = [2 1 1.2 2.2]
                for numLevels = 6:8
                    if (obj.logger.traceEnabled)
                        obj.logger.trace('### Cycle, #levels=%d ###\n', numLevels);
                    end
                    % Exact behavior only for integer cycle index
                    amg.cycle.UTestCycleCounters.cycleIndexTest(numLevels, g, 0.6);
                end
            end
        end
    end
    
    %=========================== PRIVATE METHODS==========================
    methods (Static, Access = private)
        function cycleIndexTest(numLevels, g, tol)
            % Test that cycle-index-g-cycle counters behave like g^(l-1) to
            % tolerenace tol here l=level index (1=finest).
            
            cycle = amg.cycle.BearCycle(numLevels, g);
            cycle.cycle(1);
            if (numLevels >= 3)
                %g cycle.numVisits
                ratio = 1./fac(cycle.numVisits);
                weightedError = lpnorm((ratio - g).*(1:(numLevels-2)));
                %[numLevels g weightedError]
                assertElementsAlmostEqual(weightedError, 0, 'absolute', tol);
            end
        end
    end
end
