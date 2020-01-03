classdef (Sealed) UTestFitterGriddyLs < amg.AmgFixture
    %UTestFitterGriddyLs Unit tests of a least-squares subset selection griddy algorithm.
    %   This class tests GriddyFit in isolation. GriddyFit is later used
    %   within the energy correction section of the AMG algorithm.
    
    %=========================== PROPERTIES ==============================
    properties (Constant, GetAccess = protected)
        logger = core.logging.Logger.getInstance('amg.energy.UTestGriddyFit')
        FITTER_FACTORY = amg.energy.FitterFactory;
    end
    
    %=========================== CONSTRUCTORS ============================
    methods
        function obj = UTestFitterGriddyLs(name)
            %UTestFitterGriddyLs Constructor
            %   UTestFitterGriddyLs(name) constructs a test case using
            %   the specified name.
            obj = obj@amg.AmgFixture(name);
        end
    end
    
    %=========================== SETUP METHODS ===========================

    %=========================== TESTING METHODS =========================
    methods
        function testBasic(obj) %#ok<MANU>
            % Test a basic LS fit with lambda=0.
            load hald;
            fitter = amg.energy.UTestFitterGriddyLs.FITTER_FACTORY.newInstance('griddy-ls', 'maxCaliber', 4, 'fitThreshold', 1, 'display', false);
            [b, in, fit] = fitter.fit(ingredients, heat);
            assertElementsAlmostEqual(b, [1.1533 2.1930 0.7585 0.4863]', 'relative', 1e-4);
            assertElementsAlmostEqual(in, [2 1 3 4], 'relative', 1e-16);
            assertElementsAlmostEqual(fit, 2.0117, 'relative', 1e-4);
        end
        
        function testLimitedCaliberAndFit(obj) %#ok<MANU>
            % Test limiting the interpolation caliber (subset size) and fit
            % to a threshold.
            load hald;
            fitter = amg.energy.UTestFitterGriddyLs.FITTER_FACTORY.newInstance('griddy-ls', 'maxCaliber', 3, 'fitThreshold', 9, 'display', false);
            [b, in, fit] = fitter.fit(ingredients, heat);
            assertElementsAlmostEqual(b, [0.8833 3.5507 2.1326]', 'relative', 1e-4);
            % Note: if fit is not limited, the best caliber-3 subset is [2,1,3]
            assertElementsAlmostEqual(in, [2 1 3], 'relative', 1e-16);
            assertElementsAlmostEqual(fit, 8.1281, 'relative', 1e-4);
        end
    end
    
    %=========================== PRIVATE METHODS==========================
    methods (Static, Access = private)
    end
end
