classdef CoreFixture < TestCase
    %XUNITFIXTURE A learning test of the xUnit testing framework.
    %   Detailed explanation goes here
    
    %=========================== FIELDS ==================================
    
    %=========================== CONSTRUCTORS ============================
    methods
        function self = CoreFixture(name)
            %CoreFixture Constructor
            self = self@TestCase(name);
        end
    end
    
    %=========================== SETUP METHODS ===========================
    methods
        function setUp(self) %#ok<MANU>
            %setUp Simple test fixture setup.
            %             obmeta = metaclass(self);
            %             fprintf('setUp() %s\n', obmeta.Name);
        end
        
        function tearDown(self) %#ok<MANU>
            %tearDown Simple test fixture tear-down.
            %             obmeta = metaclass(self);
            %             fprintf('tearDown() %s\n', obmeta.Name);
        end
    end
    
end

