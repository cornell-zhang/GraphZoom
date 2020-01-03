classdef (Sealed) LTestXunit < core.xunit.XunitFixture
    %LTESTXUNIT A learning test of the xUnit testing framework.
    %   Detailed explanation goes here
    
    %=========================== CONSTRUCTORS ============================
    methods
        function self = LTestXunit(name)
            %LTestXunit Constructor
            %   LTestXunit(name) constructs a test case using the
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

