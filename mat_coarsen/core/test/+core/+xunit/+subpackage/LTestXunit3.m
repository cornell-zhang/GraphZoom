classdef (Sealed) LTestXunit3 < core.xunit.XunitFixture
    %LTESTXUNIT3 A learning test of the xUnit testing framework.
    %   Detailed explanation goes here
    
    %=========================== CONSTRUCTORS ============================
    methods
        function self = LTestXunit3(name)
            %LTestXunit3 Constructor
            %   LTestXunit3(name) constructs a test case using the
            %   specified name.
            self = self@core.xunit.XunitFixture(name, 1);
        end
    end
    
    %=========================== SETUP METHODS ===========================

    %=========================== TESTING METHODS =========================
    methods
        function testXValue(self)
            assertEqual(self.x, 1);
        end
        
        function testXValueAgain(self)
            assertEqual(self.x, 1);
        end
end
    
end

