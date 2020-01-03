classdef (Sealed) LTestXunit2 < core.xunit.XunitFixture
    %LTESTXUNIT2 Another learning test of the xUnit testing framework.
    %   Detailed explanation goes here
    
    %=========================== CONSTRUCTORS ============================
    methods
        function self = LTestXunit2(name)
            %LTestXunit Constructor
            %   LTestXunit(name) constructs a test case using the
            %   specified name.
            self = self@core.xunit.XunitFixture(name, 2);
        end
    end
    
    %=========================== SETUP METHODS ===========================

    %=========================== TESTING METHODS =========================
    methods
        function testXValue(self)
            assertEqual(self.x, 2);
        end
        
        function testXValueAgain(self)
            assertEqual(self.x, 2);
        end
end
    
end

