classdef AmgFixture < TestCase
    %AMGFIXTURE AMG common test fixture.
    %   Use as a base class for test classes. Contains common testing
    %   set-up and tear-down and utility methods.
    
    %=========================== FIELDS ==================================
   properties (Constant, GetAccess = protected)
       BATCH_RUNNER    = graph.runner.BatchRunner;
   end

    %=========================== CONSTRUCTORS ============================
    methods
        function obj = AmgFixture(name)
            %PetKineticFixture Constructor
            %   PetKineticFixture(name) constructs a test case with the
            %   specified name.
            obj = obj@TestCase(name);
        end
    end  
    
    %=========================== SETUP METHODS ===========================
    methods
        function setUp(self) %#ok<MANU>
            % Initialize configuration.
            config;
        end
        
        function tearDown(self) %#ok<MANU>
            %tearDown Simple test fixture tear-down.
            %             obmeta = metaclass(self); fprintf('tearDown()
            %             %s\n', obmeta.Name);
        end
    end
    
end

