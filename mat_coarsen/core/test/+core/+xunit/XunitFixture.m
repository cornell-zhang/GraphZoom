classdef XunitFixture < core.CoreFixture
    %XUNITFIXTURE A learning test of the xUnit testing framework.
    %   Detailed explanation goes here
    
    %=========================== PROPERTIES ==============================
    properties (GetAccess = protected)
        initialX
        x
    end
    
    %=========================== CONSTRUCTORS ============================
    methods
        function self = XunitFixture(name, initialX)
            %XunitFixture Constructor
            %   TestCaseInDir(name, initialX) constructs a test case using
            %   the specified name and sets the x property to initialX
            %   during set up.
            self = self@core.CoreFixture(name);
            self.initialX = initialX;
        end
    end
    
    %=========================== SETUP METHODS ===========================
    methods
        function setUp(self)
            %setUp Simple test fixture setup.
            
            % Must call super class' set-up method. Xunit won't
            % automatically call it.
            setUp@core.CoreFixture(self);            
            
            self.x = self.initialX;
        end
        
        function tearDown(self)
            %tearDown Simple test fixture tear-down.

            self.x = 0;

            % Must call super class' set-up method. Xunit won't
            % automatically call it.
            tearDown@core.CoreFixture(self);            
        end
    end
    
end

