classdef (Sealed) UTestCycleCountersState < amg.AmgFixture
    %UTestCycleCounters Unit test state-based cycle index logic.
    %   Test that the level visitation counters lead to a correct
    %   visitation pattern in the multigrid cycle.
    
    %=========================== PROPERTIES ==============================
    properties (Constant, GetAccess = protected)
        logger = core.logging.Logger.getInstance('amg.cycle.UTestCycleCountersState')
    end
    
    %=========================== CONSTRUCTORS ============================
    methods
        function obj = UTestCycleCountersState(name)
            %UTestCycleCountersState Constructor
            %   UTestCycleCountersState(name) constructs a test case using
            %   the
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
            
             for gam = [1 2]
                for numLevels = 3
                    % Exact behavior for integer index
                    processor = amg.cycle.UTestCycleCountersState.cycleIndexTest(numLevels, gam, 0.6);
                    if (obj.logger.debugEnabled)
                        disp(processor);
                    end
                end
            end
        end
        
        function testCycleCounters(obj)
            % Test that cycle level counters are correctly used for a
            % gamma-cycle logic.
            
            for gam = [2 1 1.2 2.2]
                for numLevels = 6:9
                    % Exact behavior for integer index
                    processor = amg.cycle.UTestCycleCountersState.cycleIndexTest(numLevels, gam, 0.6);
                    if (obj.logger.debugEnabled)
                        disp(processor);
                    end
                end
            end
        end
    end
    
    %=========================== PRIVATE METHODS==========================
    methods (Static, Access = private)
        function processor = cycleIndexTest(numLevels, gam, tol)
            % Test that cycle-index-gam-cycle counters behave like g^(l-1) to
            % tolerenace tol here l=level index (1=finest).
            processor = amg.cycle.VisitPrinter;
            cycle = amg.level.Cycle(processor, gam, numLevels, 1);
            cycle.run([], []);
            if (numLevels > 1)
                %g cycle.numVisits
                ratio = 1./fac(processor.numVisits(1:end-1));
                weightedError = lpnorm((ratio - gam).*(1:(numLevels-2)));
                %[numLevels g weightedError]
                if (isIntegral(gam))
                    assertElementsAlmostEqual(weightedError, 0, 'absolute', 1e-14);
                else
                    assertElementsAlmostEqual(weightedError, 0, 'absolute', tol);
                end
            end
        end
    end
end
