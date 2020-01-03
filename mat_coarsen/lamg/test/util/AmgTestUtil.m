classdef (Sealed) AmgTestUtil < amg.AmgFixture
    %AmgTestUtil Test utilities.
    %   This class  centralizes test utilities used by all test suites.
    
    %=========================== CONSTANTS ===============================
    properties (Constant, GetAccess = public)
        MAX_EDGES       = 300                               % Maximum # edges in graphs of interest during tests
        GENERATOR       = graph.generator.GeneratorFactory    % Graph generator mother object
    end
    properties (Constant, GetAccess = protected)
        logger          = core.logging.Logger.getInstance('amg.runner.UTestRelaxAcf')
    end
    
    %=========================== CONSTRUCTORS ============================
    methods (Access = private)
        function obj = AmgTestUtil
            %Hide constructor in utility class.
        end
    end
    
    %=========================== TESTING METHODS =========================
    methods (Static)
        function index = bestAcfIndex(dummy1, data, dummy2) %#ok
            % A functor that output the relaxation scheme string corresponding to the best ACF.
            [dummy3, index] = min(data(1:end-1)); %#ok
            index = index(1);
        end
        
        function result = compareMethods(batchReader, selectedGraphs, methodLabels, methodInstances, ...
                resultComputer)
            % Compute ACFs/some other statistics of several relxaation methods in a batch run.
            
            % Default: computes ACF using the standard ACF computer
            if (nargin < 5)
                resultComputer = lin.api.AcfComputer;
            end
            
            runner = lin.runner.RunnerMethodComparison(@Problems.laplacianHomogeneous, ...
                resultComputer);
            runner.addMethods(methodLabels, methodInstances);
            if (isempty(selectedGraphs))
                result = amg.AmgFixture.BATCH_RUNNER.run(batchReader, ...
                    runner);
            else
                result = amg.AmgFixture.BATCH_RUNNER.run(batchReader, ...
                    runner, selectedGraphs);
            end
        end
        
        function problem = newGridProblem(N, varargin)
            % Construct a d-D grid test problem of size N.
            g = Graphs.grid('fd', N, varargin{:});
            problem = Problems.laplacian(g, zeros(g.numNodes, 1));
        end
        
        function problem = loadProblem(key, varargin)
            % Load a MAT-formatted problem from the data directory by key.
            g = Graphs.testInstance(key);
            problem = Problems.laplacian(g, zeros(g.numNodes, 1));
        end        
    end   
end
