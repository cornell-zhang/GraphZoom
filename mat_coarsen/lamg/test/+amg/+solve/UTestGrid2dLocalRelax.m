classdef (Sealed) UTestGrid2dLocalRelax < amg.AmgFixture
    %UTestGrid2dLocalRelax Unit test two-level cycle ACF for a 2-D grid
    %graph with local relaxation coarsening.
    %   This class computes cycle ACFs on various graph instances.
    %
    %   @DEPRECATED
    %   See also: CoarseningStrategy.
    
    %=========================== PROPERTIES ==============================
    properties (Constant, GetAccess = protected)
        logger          = core.logging.Logger.getInstance('amg.solve.UTestGrid2dLocalRelax')
    end
    
    %=========================== CONSTRUCTORS ============================
    methods
        function obj = UTestGrid2dLocalRelax(name)
            %UTestGrid2dLocalRelax Constructor
            %   UTestGrid2dLocalRelax(name) constructs a test case using
            %   the specified name.
            obj = obj@amg.AmgFixture(name);
        end
    end
    
    %=========================== SETUP METHODS ===========================
    methods
        function setUp(obj)
            setUp@amg.AmgFixture(obj);
            
            if (obj.logger.infoEnabled)
                obj.logger.info('\n');
                obj.logger.info('%-2s %-7s %-4s %-2s %-12s %-7s %-6s %-6s %-6s %-6s %-4s\n', ...
                    'g', 'energy', 'n', 'nu', 'aggregation', 'ratio', ...
                    'HCR', 'ACF', 'Work', 'beta', '#lev');
                obj.logger.info('==========================================================================\n');
            end
        end
    end
    
    %=========================== TESTING METHODS =========================
    methods
        function testFdTwoLevel(obj)
            % Multiple two-level 2-D 5-point grid cycle ACF test cases -
            % constant energy correction.
            nu = 3;
            n = 15; %90;
            mlOptions = obj.mlExperimentOptions(nu, 'random', 0, 'flat', 4/3, ...
                'tvNum', 10, ...
                'cycleIndex', 1.5, ...
                'setupNumAggLevels', 100, ...
                'radius', 10, ...
                'plotCoarsening', false, ...
                'coarseningDebugEdgeIndex', -1);
            obj.mlExperiment('fd', n, mlOptions);
        end
        
        function testBatteryLocalRelax(obj)
            % Multiple two-level 2-D 9-point grid cycle ACF test cases -
            % constant energy correction.
            cycleIndex = 1.5;
            mu = 4/3;
            %nu = 3;
            for problemType = {'fd'} %{'fd', 'fe'}
                for n = 15 %30 %60 %[15 30 60 90] %[15 30 60 120 180 200]
                    for nu = 2 %1:4
                        mlOptions = obj.mlExperimentOptions(nu, 'random', 0, 'flat', mu, ...
                            'tvNum', 10, ...
                            'tvNumLocalSweeps', 5, ...
                            'cycleIndex', cycleIndex, ...
                            'setupNumAggLevels', 100);
                        obj.mlExperiment(problemType{1}, n, mlOptions);
                    end
                end
            end
        end
        
        function testBatteryGlobalRelax(obj)
            % A less expensive setup - globally relaxed TVs. No local HCR
            % sweeps.
            cycleIndex = 1.5;
            mu = 4/3;
            %nu = 3;
            for problemType = {'fd'} %{'fd', 'fe'}
                for n = [5 10] %[15 30 60 120 180]
                    for nu = 2 %1:4
                        mlOptions = obj.mlExperimentOptions(nu, 'random', 5, 'flat', mu, ...
                            'tvNum', 10, ...
                            'aggregationUpdate', 'affinity', ...
                            'cycleIndex', cycleIndex, ...
                            'setupNumAggLevels', 100);
                        obj.mlExperiment(problemType{1}, n, mlOptions);
                        %pause
                    end
                end
            end
        end
    end
    
    %=========================== PRIVATE METHODS =========================
    methods (Access = private)
        function mlOptions = mlExperimentOptions(obj, nu, tvInitialGuess, kappa, ...
                energyCorrectionType, mu, varargin) %#ok<MANU>
            % Options for a multi-level experiment
            mlOptions = amg.api.Options.fromStruct(...
                amg.solve.UTestGrid2dLocalRelax.defaultOptions(), ...
                'nuDefault', nu, ...
                'tvInitialGuess', tvInitialGuess, ...
                'tvSweeps', kappa, ...
                'minCoarseningRatio', 0.3, ...
                'maxHcrAcf', 0.4, ...
                'energyCorrectionType', energyCorrectionType, ...
                'rhsCorrectionFactor', mu, ...
                varargin{:});
        end
        
        function [hcr, acf] = mlExperiment(obj, problemType, n, mlOptions)
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
            if (~isempty(mlOptions.randomSeed))
                setRandomSeed(mlOptions.randomSeed);
            end
            
            % Compute ACF in batch mode
            runner          = amg.runner.RunnerCycleAcf('laplacian', mlOptions, ...
                'steadyStateTol', 1e-2, 'output', 'full');
            result          = amg.AmgFixture.BATCH_RUNNER.run(batchReader, runner);
            
            % Report results
            if (obj.logger.debugEnabled)
                %if (mlOptions.plotCoarsening)
                amg.solve.UTestGrid2dLocalRelax.printResults(result);
                %amg.solve.UTestGrid2dLocalRelax.plotResults(result);
            end
            hcr     = result.details{1}.setup.hcr(1);
            acf     = result.details{1}.acf;
            % Compute maximum off-diagonal element in coarse level matrix
            %             Ac              =
            %             result.details{1}.setup.level{2}.A; Ac
            %             = Ac - diag(diag(Ac)); minOffDiagonal  =
            %             full(max(Ac(:)));
            if (obj.logger.infoEnabled)
                if (isempty(mlOptions.coarseningRatio))
                    sCoarseningRatio = '-';
                else
                    sCoarseningRatio = sprintf('[%-1d,%-1d]', mlOptions.coarseningRatio);
                end
                obj.logger.info('%-2s %-7s %-4d %-2d %-12s %-7s %-6.3f %-6.3f %-6.2f %-6.2f %-4d\n', ...
                    problemType, mlOptions.energyCorrectionType, ...
                    n, mlOptions.nuDefault, ...
                    mlOptions.aggregationType, sCoarseningRatio, ...
                    hcr, acf, result.data(1,4), acf^(1/result.data(1,4)), result.data(1,5));
            end
        end
    end
    
    methods (Static, Access = private)
        function mlOptions = defaultOptions()
            % Standard Multi-level options for a two-level experiment.
            % Default multilevel mlOptions.
            mlOptions                           = amg.api.Options;
            
            % Debugging flags
            mlOptions.logLevel                  = 1;
            %            mlOptions.plotCoarsening            = true;
            mlOptions.plotLevels               = false;
            mlOptions.randomSeed                = 14;
            
            % Multi-level cycle
            mlOptions.cycleDirectSolver         = 1;
            mlOptions.numCycles                 = 20;
            mlOptions.errorNorm                 = @errorNormResidual;
            mlOptions.combinedIterates          = 1;
            mlOptions.setupNumAggLevels            = 100;
            mlOptions.cycleIndex                = 1.2;
            mlOptions.nuDesign                  = 'split_evenly';
            
            % Test vectors
            mlOptions.tvNum                     = 10;
            
            % Aggregation
            mlOptions.aggregationType           = 'limited';
            mlOptions.aggregationUpdate         = 'local-relax';
            mlOptions.coarseningRatio           = [];
            mlOptions.nuOptimization            = false;
            mlOptions.minCoarseSize             = 10;
            
            % Energy correction
            mlOptions.energyCorrectionType      = 'flat';
            
            % Elimination
            mlOptions.elimination               = false;
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
            n       = level.g.metadata.attributes.n(1);
            %eb      = result.details{1}.setup.level{2}.energyBuilder;
            
            %coord   = level.g.coord;
            %t       = reshape(coord(:,1),[n n]);
            %s       = reshape(coord(:,2),[n n]);
            [tt,ss]    = ndgrid('fd', 1:n, 1:n);
            
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
            %R = abs(r);
            %[y, i] = sort(R,'descend');
            %[i(1:20) y(1:20)]
            %find(R >= 0.95*max(R))
            
            
            %             % Asymptotic cycle vector figure(1); surf(t, s,
            %             reshape(x,[n n])); title('Asymptotic Cycle
            %             Error'); xlabel('t'); ylabel('s');
            % %             %plot(x);
            
            % Asymptotic cycle residual
            figure(n);
            %surf(t, s, reshape(abs(r),[n n])); surf(t, s, reshape(r,[n
            %n]));
            surf(tt, ss, reshape(r,[n n]));
            view(2); colorbar;
            title('Asymptotic Cycle Residual');
            xlabel('t1');
            ylabel('t2');
            
            %             figure(3); surf(tt, ss, reshape(R,[n n]));
            %             view(2); colorbar; title('Asymptotic Cycle
            %             Residual'); xlabel('i1'); ylabel('i2');
            
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
