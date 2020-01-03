classdef (Sealed) LTestIndexing < core.CoreFixture
    %LTESTINDEXING A learning test of overriding indexing.
    %   Detailed explanation goes here
    
    %=========================== FIELDS ==================================
    properties (GetAccess = private, SetAccess = private)
        d % data object to play with; has fixed data
        drand % data object to play with; has random data
    end
    
    %=========================== CONSTRUCTORS ============================
    methods
        function self = LTestIndexing(name)
            self = self@core.CoreFixture(name);
        end
    end
    
    %=========================== SETUP METHODS ===========================
    methods
        function setUp(self)
            setUp@core.CoreFixture(self);
            self.d = core.lang.MyDataClass(5+zeros(3,4),'Test001');
            self.drand = core.lang.MyDataClass(randi(9,3,4),'Test002');
        end
        
        function tearDown(self)
            %tearDown Simple test fixture tear-down.
            clear self.d self.drand;
            tearDown@core.CoreFixture(self);
        end
    end
    
    %=========================== TESTING METHODS =========================
    methods
        function testIndexReferencing(self)
            assertEqual(self.d(2,3), 5);
            %            fprintf('%d\n',self.drand(2,3));
            assertTrue(self.drand(2,3) > 0);
        end
        
        function testClearingDVariables(self)
            %            fprintf('%d\n',self.drand(2,3)); % Should report a
            %            different random value than the previous method's
            assertTrue(self.drand(2,3) > 0);
        end
    end
    
end

