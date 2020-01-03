classdef (Sealed) UTestCycleAcfGrid2dTwoLevel < amg.AmgFixture
    %UTestCycleAcfGrid2dTwoLevel Unit test two-level cycle ACF for a 2-D grid graph.
    %   This class computes cycle ACFs on various graph instances.
    
    %=========================== PROPERTIES ==============================
    properties (Constant, GetAccess = protected)
        logger          = core.logging.Logger.getInstance('amg.solve.UTestCycleAcfGrid2dTwoLevel')
    end
    
    %=========================== CONSTRUCTORS ============================
    methods
        function obj = UTestCycleAcfGrid2dTwoLevel(name)
            %UTestCycleAcfGrid2dTwoLevel Constructor
            %   UTestCycleAcfGrid2dTwoLevel(name) constructs a test case using the
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
                obj.logger.info('%-2s %-7s %-4s %-2s %-9s %-5s %-12s %-7s %-6s %-6s %-7s\n', ...
                    'g', 'energy', 'n', 'nu', 'Initial', 'kappa', 'aggregation', 'ratio', ...
                    'HCR', 'ACF', 'offdiag');
                obj.logger.info('================================================================================\n');
            end
        end
    end
    
    %=========================== TESTING METHODS =========================
    methods
        function testFdGeometricNoEnergyCorrection(obj)
            % A single two-level test of cycle ACF for a 2-D grid graph with geometric
            % coarsening.
            obj.twoLevelExperimentFlatFactor('fd', 30, 3, ...
                'fourier', 5, 'geometric', [1 2], 4/3, 1.5, 'none');
        end
        
        function inactiveTestFdTwoLevelNodalCgo(obj)
            % Multiple two-level 2-D 5-point grid cycle ACF test cases - constant
            % energy correction.
            nu = 4;
            n = 12; %%30; %60;
        	obj.multiLevelExperimentFlatFactor('fd', n, nu, ...
                'random', 20, 'stagewise', [2 1], 'nodal', 0.1, 1.5, 100);
        end
        
        function testFdTwoLevelNodalRhs(obj)
            % Multiple two-level 2-D 5-point grid cycle ACF test cases - constant
            % energy correction.
            nu = 3;
            n = 12; %%30;
        	obj.multiLevelExperimentFlatFactor('fd', n, nu, ...
                'fourier', 10, 'geometric', [1 2], 'nodal-rhs', [], 1.5, 2);
        end
               
        function testFdGeometricSemiCoarseningFlatFactorParametric(obj)
            % Geometric semi-coarsening in which flat-ls for both random
            % and fourier is worse than flat, the latter yielding the ideal
            % ACF ~ 1/3. That's because there is no single factor that fits
            % all TVs: it's slope-orientation-dependent.
            problemType = 'fd';
            nu = 3;
            n = 12; %%30; %60;
            obj.twoLevelExperimentFlatFactor(problemType, n, nu, ...
                'fourier', 5, 'geometric', [1 2], 4/3, 1.5, 'flat');
            obj.twoLevelExperimentFlatFactor(problemType, n, nu, ...
                'fourier', 5, 'geometric', [1 2], [], 1.5, 'flat-ls');
            obj.twoLevelExperimentFlatFactor(problemType, n, nu, ...
                'random', 10, 'geometric', [1 2], [], 1.5, 'flat-ls');
        end
        
        function inactiveTestFdGeometricCoarseningFlatFactorParametric(obj)
            % Two-level mu-HCR vs. mu (not in use any more, as HCR predicts
            % an ideal interpolation, not a mu-corrected caliber-1
            % interpolation).
            problemType = 'fd';
            nu = 3;
            n = 12; %%30;% 60;
            alpha = (1:0.4:2)';
            hcrMu = zeros(size(alpha));
            hcrEnergyCorrection = zeros(size(alpha));
            for i = 1:numel(alpha)
                hcrMu(i) = obj.twoLevelExperimentFlatFactor(problemType, n, nu, ...
                    'fourier', 5, 'geometric', [2 2], alpha(i), 2.0);
                hcrEnergyCorrection(i) = obj.twoLevelExperimentFlatFactor(problemType, n, nu, ...
                    'fourier', 5, 'geometric', [2 2], alpha(i)/2, 2.0);
            end
%             figure(1);
%             clf;
%             plot(alpha, hcrMu, alpha, hcrEnergyCorrection);
%             xlabel('\mu');
%             ylabel('HCR ACF');
%             title(sprintf('HCR ACF with multipliers \\mu, \\mu/2 for 2-D %dx%d Grid + Geometric Coarsening', n, n));
%             legend('\mu', '\mu/2', 'Location', 'Northwest');
%             save_figure('png', sprintf('hcr/hcr_comparison_grid_%dx%d.png', n, n));
        end

        function testFdTwoLevel(obj)
            % A single two-level test of cycle ACF for a 2-D grid graph
            % with algebraic coarsening.
            problemType = 'fd';
            nu = 3;
            n = 12; %%30;
            alpha = 4/3;
        	obj.twoLevelExperimentFlatFactor(problemType, n, nu, ...
                'random', 10, 'hcr', [], alpha, 2.0);
        end
       
        function testFdTwoLevelLimitedCoarsening(obj)
            % A single two-level test of cycle ACF for a 2-D grid graph with geometric
            % coarsening.
            problemType = 'fd';
            nu = 3;
            n = 12; %%30;
            obj.multiLevelExperimentLimited(problemType, n, nu, ...
                'random', 10, 1.5, 0.5, 'flat', 4/3, 2);
        end
        
        function inactiveTestFdTwoLevelGeometricAdaptive(obj)
            % Multiple two-level 2-D 5-point grid cycle ACF test cases - constant
            % energy correction.
            %
            % Inactive test: no longer letting level.rhsMu be publicly-settable.
            nu = 4;
            n = 12; %%30;
        	obj.multiLevelExperimentFlatFactor('fd', n, nu, ...
                'random', 10, 'geometric', [2 2], 'adaptive', [], 2.0, 2);
        end
        
        function testFdMultiLevelLimitedCoarsening(obj)
            % A single two-level test of cycle ACF for a 2-D grid graph with geometric
            % coarsening.
            problemType = 'fd';
            nu = 3;
            n = 12; %%30; %60;
            obj.multiLevelExperimentLimited(problemType, n, nu, ...
                'random', 10, 1.5, 0.5, 'flat', 4/3, 2);
        end
        
        function testFdMultilevel(obj)
            % Multiple two-level 2-D 5-point grid cycle ACF test cases - constant
            % energy correction.
            nu = 3;
            n = 12; %%30; %60;
            alpha = 4/3;
        	obj.multiLevelExperimentFlatFactor('fd', n, nu, ...
                'random', 10, 'hcr', [], 'flat', alpha, 1.5);
        end
        
        function testFeMultilevel(obj)
            % Multiple two-level 2-D 5-point grid cycle ACF test cases - constant
            % energy correction.
            nu = 3;
            n = 12; %%30; %60;
            alpha = 4/3;
        	obj.multiLevelExperimentFlatFactor('fe', n, nu, ...
                'random', 10, 'hcr', [], 'flat-ls', alpha, 1.5);
        end
        
        function inactiveTestBatteryNodal(obj)
            % Multiple two-level 2-D grid cycle ACF test cases - nodal
            % energy correction.
            problemType = 'fd';
            nu = 3;
            n = 12; %%30; %60;
        	obj.twoLevelExperimentNodal(problemType, n, nu, ...
                'fourier', 5, 'geometric', [2 2], 0.1);
        	obj.twoLevelExperimentNodal(problemType, n, nu, ...
                'fourier', 5, 'geometric', [1 2], 0.1);
        	obj.twoLevelExperimentNodal(problemType, n, nu, ...
                'random', 10, 'geometric', [2 2], 0.1);
            
        	obj.twoLevelExperimentNodal(problemType, n, nu, ...
                'fourier', 5, 'hcr', [], 0.1);
        	obj.twoLevelExperimentNodal(problemType, n, nu, ...
                'random', 10, 'hcr', [], 0.1);
        end
        
        function testBatteryFlatFactorTwoLevel(obj)
            % Multiple two-level 2-D grid cycle ACF test cases - constant
            % energy correction.
            problemType = 'fd';
            nu = 3;
            n = 12; %%30; %60;
            alpha = 1.43;
        	obj.twoLevelExperimentFlatFactor(problemType, n, nu, ...
                'fourier', 5, 'geometric', [2 2], alpha);
        	obj.twoLevelExperimentFlatFactor(problemType, n, nu, ...
                'fourier', 5, 'geometric', [1 2], alpha);
        	obj.twoLevelExperimentFlatFactor(problemType, n, nu, ...
                'random', 10, 'geometric', [2 2], alpha);
            
        	obj.twoLevelExperimentFlatFactor(problemType, n, nu, ...
                'fourier', 5, 'hcr', [], alpha);
        	obj.twoLevelExperimentFlatFactor(problemType, n, nu, ...
                'random', 10, 'hcr', [], alpha);
        end
        
        function testBatteryFlatFactorMultiLevel(obj)
            % Multiple two-level 2-D 9-point grid cycle ACF test cases -
            % constant energy correction.
            alpha = 4/3;
            cycleIndex = 1.5;
            for energyCorrectionType = {'flat', 'flat-ls'}
                for problemType = {'fd'} %{'fd', 'fe'}
                    for n = [5 10] %[30 60 90]
                        obj.multiLevelExperimentFlatFactor(problemType{1}, n, 3, ...
                            'random', 10, 'hcr', [], energyCorrectionType{1}, alpha, cycleIndex);
                    end
                end
            end
        end
        
        function inactiveTestBatteryCgo(obj)
            % Multiple two-level 2-D 9-point grid cycle ACF test cases -
            % constant energy correction.
            cycleIndex = 1.5;
            for problemType = {'fd'} %{'fd', 'fe'}
                for nu = 2:3
                    for n = [5 10] %[30 60 90]
                        obj.multiLevelExperimentFlatFactor(problemType{1}, n, nu, ...
                            'random', 10, 'stagewise', [2 1], 'nodal', 0.1, cycleIndex, 100);
                    end
                end
            end
        end
                        
        function testBatteryFlatFactorLimited(obj)
            % Multiple two-level 2-D 9-point grid cycle ACF test cases -
            % constant energy correction.
            cycleIndex = 1.5;
            alpha = 0.5;
            mu = 4/3;
            for energyCorrectionType = {'flat', 'flat-ls'}
                for problemType = {'fd'} %{'fd', 'fe'}
                    for n = [5 10] %[30 60 90]
                        obj.multiLevelExperimentLimited(problemType{1}, n, 3, ...
                            'random', 10, cycleIndex, alpha, energyCorrectionType{1}, mu, 100);
                    end
                end
            end
        end
    end
    
    %=========================== PRIVATE METHODS =========================
    methods (Access = private)
        function [hcr, acf] = twoLevelExperimentNodal(obj, problemType, n, nu, tvInitialGuess, kappa, ...
                aggregationType, coarseningRatio, lambda)
            % A single two-level experiment of nodal energy correction.
            % Returns the HCR ACF (hcr) and two-level ACF (acf).
            
            mlOptions = amg.solve.UTestCycleAcfGrid2dTwoLevel.twoLevelOptions(...
                nu, tvInitialGuess, kappa, aggregationType, coarseningRatio, lambda);
            [hcr, acf] = obj.twoLevelExperiment(problemType, n, mlOptions);
        end

        function [hcr, acf] = twoLevelExperimentFlatFactor(obj, problemType, n, nu, tvInitialGuess, kappa, ...
                aggregationType, coarseningRatio, alpha, cycleIndex, energyCorrectionType)
            % A single two-level experiment of constant energy correction.
            % Returns the HCR ACF (hcr) and two-level ACF (acf).
            
            if (nargin < 10)
                cycleIndex = 1.2;
            end
            if (nargin < 11)
                energyCorrectionType = 'flat';
            end
            mlOptions = amg.solve.UTestCycleAcfGrid2dTwoLevel.twoLevelOptions(...
                nu, tvInitialGuess, kappa, aggregationType, coarseningRatio, []);
            mlOptions.energyCorrectionType      = energyCorrectionType;
            mlOptions.rhsCorrectionFactor       = alpha;
            mlOptions.cycleIndex                = cycleIndex;
            
            [hcr, acf] = obj.twoLevelExperiment(problemType, n, mlOptions);
        end

        function [hcr, acf] = multiLevelExperimentLimited(obj, problemType, n, nu, ...
                tvInitialGuess, kappa, ...
                cycleIndex, targetCoarseningRatio, energyCorrectionType, alpha, numLevels)
            % A single two-level experiment of constant energy correction
            % and limited coarsening. Returns the HCR ACF (hcr) and two-level ACF (acf).
            
            mlOptions = amg.solve.UTestCycleAcfGrid2dTwoLevel.twoLevelOptions(...
                nu, tvInitialGuess, kappa, 'limited', [], []);
            mlOptions.cycleIndex                = cycleIndex;
            mlOptions.minCoarseningRatio        = targetCoarseningRatio;
            mlOptions.energyCorrectionType      = energyCorrectionType;
            mlOptions.rhsCorrectionFactor       = alpha;
            mlOptions.setupNumAggLevels            = numLevels;
            mlOptions.minCoarseSize             = 10;
            
            [hcr, acf] = obj.twoLevelExperiment(problemType, n, mlOptions);
        end
        
        function [hcr, acf] = multiLevelExperimentFlatFactor(obj, problemType, n, nu, tvInitialGuess, kappa, ...
                aggregationType, coarseningRatio, energyCorrectionType, alpha, cycleIndex, numLevels)
            % A single multi-level experiment of constant energy correction.
            % Returns the HCR ACF (hcr) and two-level ACF (acf).
            
            if (nargin < 11)
                cycleIndex = 1.2;
            end
            if (nargin < 12)
                numLevels = 100;
            end
            mlOptions = amg.solve.UTestCycleAcfGrid2dTwoLevel.twoLevelOptions(...
                nu, tvInitialGuess, kappa, aggregationType, coarseningRatio, alpha);
            mlOptions.energyCorrectionType      = energyCorrectionType;
            mlOptions.rhsCorrectionFactor       = alpha;
            mlOptions.cycleIndex                = cycleIndex;
            mlOptions.setupNumAggLevels            = numLevels;
            mlOptions.minCoarseSize             = 10;
            %mlOptions.nuOptimization            = true;
            
            [hcr, acf] = obj.twoLevelExperiment(problemType, n, mlOptions);
        end
        
        function [hcr, acf] = twoLevelExperiment(obj, problemType, n, mlOptions)
            % A single two-level experiment. Returns the HCR ACF (hcr) and
            % two-level ACF (acf).
            
            % Prepare input grid graphs
            batchReader = graph.reader.BatchReader;
            dim = 2;
            %            for n = N
            switch (problemType)
                case 'fd',
                    g = Graphs.grid('fd', ones(dim,1)*n, 'normalized', true); % Normalized Laplacian
                case 'fe',
                    g = Graphs.grid('fe', ones(dim,1)*n, 'normalized', true);
            end
            
            %Normalized Laplacian eigs(g.laplacian, 5, 'sm') %TODO: move
            %eigenvalue test to a separate Generator test suite
            batchReader.add('graph', g);
            %            end
            
            % Fix random seed
%             if (~isempty(mlOptions.randomSeed))
%                 setRandomSeed(mlOptions.randomSeed);
%             end
            
            % Compute ACF in batch mode
            solver = Solvers.newSolver('lamg', mlOptions, ...
                'steadyStateTol', 1e-2, 'output', 'full', 'maxDirectSolverSize', 10);
            runner = lin.runner.RunnerSolver(@Problems.laplacianHomogeneous, 'lamg', solver);
            runner.solverContext = lin.runner.SolverContext;
            result          = amg.AmgFixture.BATCH_RUNNER.run(batchReader, runner);
            
            % Report results
            if (obj.logger.debugEnabled)
                amg.solve.UTestCycleAcfGrid2dTwoLevel.printResults(result);
                %                amg.solve.UTestCycleAcfGrid2dTwoLevel.plotResults(result);
            end
            %            hcr     = result.details{1}.setup.hcr(1);
            hcr = -1;
            acf     = result.details{1}.acf;
            % Compute maximum off-diagonal element in coarse level matrix
            Ac              = result.details{1}.setup.level{2}.A;
            Ac              = Ac - diag(diag(Ac));
            minOffDiagonal  = full(max(Ac(:)));
            if (obj.logger.infoEnabled)
                if (isempty(mlOptions.coarseningRatio))
                    sCoarseningRatio = '-';
                else
                    sCoarseningRatio = sprintf('[%-1d,%-1d]', mlOptions.coarseningRatio);
                end
                obj.logger.info('%-2s %-7s %-4d %-2d %-9s %-5d %-12s %-7s %-6.3f %-6.3f %-7.3f\n', ...
                    problemType, mlOptions.energyCorrectionType, ...
                    n, mlOptions.nuDefault, mlOptions.tvInitialGuess, mlOptions.tvSweeps, ...
                    mlOptions.aggregationType, sCoarseningRatio, ...
                    hcr, acf, minOffDiagonal);
            end
        end
    end
    
    methods (Static, Access = private)
        function mlOptions = defaultOptions()
            % Default multilevel mlOptions.
            mlOptions                       = amg.api.Options;
            
            mlOptions.minAggregationStages  = 1;
            
            mlOptions.cycleDirectSolver     = 1;
            mlOptions.numCycles             = 20;
%            mlOptions.errorNorm             = @errorNormResidual;
            
            mlOptions.logLevel              = 1; %2;
            mlOptions.combinedIterates      = 1;
        end
        
        function mlOptions = twoLevelOptions(nu, tvInitialGuess, kappa, ...
                aggregationType, coarseningRatio, lambda)
            % Multi-level options for a two-level experiment.
            mlOptions                           = amg.solve.UTestCycleAcfGrid2dTwoLevel.defaultOptions();
            %mlOptions.plotCoarsening           = true;
            %mlOptions.plotLevels               = true;
            %mlOptions.randomSeed                = 14;
            
            mlOptions.setupNumAggLevels        = 2;
            mlOptions.cycleIndex                = 1.2;
            mlOptions.nuDefault                 = nu; % For controlled ACF
            mlOptions.nuDesign                  = 'post'; %'split_evenly'; %'pre';
            mlOptions.maxDirectSolverSize       = 10;
            %mlOptions.relaxType                 = 'gs-random';
            %mlOptions.relaxAdaptive             = true;
            
            % TV options
            mlOptions.tvInitialGuess            = tvInitialGuess;
            mlOptions.tvNum                     = 10;
            mlOptions.tvSweeps                  = kappa;
            
            % Fix aggregation to geometric
            mlOptions.aggregationUpdate         = 'affinity-energy-mex'; %'energy-min';
            mlOptions.aggregationType           = aggregationType;
            mlOptions.coarseningRatio           = coarseningRatio;
            mlOptions.nuOptimization            = false;
            mlOptions.minCoarseSize             = 10;
            mlOptions.minCoarseningRatio        = 0.3;
            mlOptions.maxHcrAcf                 = 0.4;
            
            mlOptions.elimination               = false; % No elimination levels in this test suite, only AGG coarsening
            mlOptions.energyCorrectionType      = 'nodal';%'ls-sum';%'constant'; %'ls-sum';%'ls-term';
            mlOptions.energyResidualFactor      = lambda;
            mlOptions.maxCoarseRelaxAcf         = 0.5;
            %mlOptions.energyCaliber             = 2;%1; %2;
            %mlOptions.energyFitThreshold        = 0;%0.01;
            %mlOptions.energyMinWeight           = -Inf;%0; %0.01;
            %mlOptions.energyFitDebug            = true;
            %mlOptions.energyOutFile             = 'grid2d-twolevel-nodal';
            %mlOptions.energyDebugEdgeIndex      = 1572; %612; %681; %142;
        end
        
        function printResults(result)
            % Print results to standard output (fid=1)
            printerFactory  = graph.printer.PrinterFactory;
            printer         = printerFactory.newInstance('text', result, 1);
            printer.addIndexColumn('#', 3);
            printer.addColumn('Group'    , 's', 'field'   , 'metadata.key',         'width', 30);
            printer.addColumn('#Nodes'   , 'd', 'field'   , 'metadata.numNodes',   	'width',  8);
            printer.addColumn('#Edges'   , 'd', 'field'   , 'metadata.numEdges',   	'width',  9);
            printer.addColumn('ACF'      , 'f', 'field'   , 'data(1)',             	'width',  7, 'precision', 2);
            printer.addColumn('Work'     , 'f', 'field'   , 'data(4)',             	'width',  8, 'precision', 2);
            printer.addColumn('#lev'     , 'd', 'field'   , 'data(5)',             	'width',  5);
            printer.run();
        end
        
        function plotResults(result)
            % Debugging plots
            level   = result.details{1}.setup.level{1};
            n       = level.g.metadata.attributes.n;
            %eb      = result.details{1}.setup.level{2}.energyBuilder;
            
            coord   = level.g.coord; 
            t       = reshape(coord(:,1), n);
            s       = reshape(coord(:,2), n);
            [tt,ss]    = ndgrid('fd', 1:n(1), 1:n(2));
            
            %            T = [t(:) s(:)];
            %
            %             edge    = level.g.edge; %edgeCoord =
            %             0.5*(level.g.coord(edge(:,1),:) +
            %             level.g.coord(edge(:,2),:)); edgeCoord =
            %             0.5*(T(edge(:,1),:) + T(edge(:,2),:)); tri     =
            %             delaunay(edgeCoord(:,1), edgeCoord(:,2));
            x = result.details{1}.asymptoticVector;
            A = level.A;
            r = A*x;
            
            % Asymptotic cycle vector
            figure(1);
            surf(t, s, reshape(x,n));
            title('Asymptotic Cycle Error');
            xlabel('t');
            ylabel('s');
%             %plot(x);
            
            % Asymptotic cycle residual
            figure(2);
            %surf(t, s, reshape(abs(r),[n n]));
            surf(t, s, reshape(r,n));
            view(2); colorbar;
            title('Asymptotic Cycle Residual');
            xlabel('t1');
            ylabel('t2');

            figure(3);
            surf(tt, ss, reshape(abs(r),n));
            view(2); colorbar;
            title('Asymptotic Cycle Residual');
            xlabel('i1');
            ylabel('i2');

            %             % Goodness-of-fit to TVs figure(3);
            %             surf(reshape(eb.fit,n*ones(1,dim)./mlOptions.coar
            %             seningRatio)); view(2); colorbar; title('Fit
            %             Value'); xlabel('t'); ylabel('s');
            
            %             % Fit statsistics figure(101); trisurf(tri,
            %             edgeCoord(:,1), edgeCoord(:,2),
            %             eb.numInterpTerms); view(2); colorbar;
            %             title('#Coarse terms interpolated to a fine
            %             term'); xlabel('t'); ylabel('s');
            %
            %             figure(102); trisurf(tri, edgeCoord(:,1),
            %             edgeCoord(:,2), eb.fit); view(2); colorbar;
            %             title('Energy Interpolation Fit'); xlabel('t');
            %             ylabel('s');
            %
            %             % Display the worst fits
            %             xx=g.metadata.attributes.subscript{1}(edge);
            %             yy=g.metadata.attributes.subscript{2}(edge);
            %             fitData = [xx(:,1) yy(:,1) xx(:,2) yy(:,2)
            %             eb.fit]; badFit  = fitData(fitData(:,5) >
            %             2*median(eb.fit),:); disp(sortrows(badFit,[1
            %             2]));
            %
            %             % TV plot figure(201); x = level.x(:,1); surf(t,
            %             s, reshape(x,[n n])); title('TV #1');
            %             xlabel('t'); ylabel('s');
            % %             %plot(x);
        end
        
    end
end
