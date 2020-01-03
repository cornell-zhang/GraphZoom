classdef (Sealed) UTestGraphPlotter < graph.GraphFixture
    %UTestGraphPlotter Test the R(t) discretization scheme.
    %   Given several noise-free data sets from Dan, we compare r with our
    %   R(t;a). Since there's no noise, if we set a to the exact parameter
    %   vector (known for these simulated data sets), then R(t) must be r.
    %   This tests that our discretization of R is the same as Dan's.
    
    %=========================== PROPERTIES ==============================
    properties (Constant, GetAccess = protected)
        logger = core.logging.Logger.getInstance('graph.plotter.UTestGraphPlotter')
    end
    
    %=========================== CONSTRUCTORS ============================
    methods
        function obj = UTestGraphPlotter(name)
            %UTestGraphPlotter Constructor
            %   UTestDisc(name) constructs a test case using
            %   the specified name.
            obj = obj@graph.GraphFixture(name);
        end
    end
    
    %=========================== SETUP METHODS ===========================
    
    %=========================== TESTING METHODS =========================
    methods
        function testGraphAndPotentialPlot(obj)
            % A simple test of plotting a simple graph and the s-t potential
            % and current field for unit current.
            g = Graphs.grid([4 4]);
            obj.graphTest(g, 1);
        end
        
%         function testGraphWithReverseEdge(obj)
%             % The same as testGraphAndPotentialPlot(), only that we flip an
%             % edge in the graph to see if negative currents can be
%             % produced.
%             
%             edgeData = graph.plotter.MaxFlowFixture.EDGE_DATA;
%             % Flip the s-u edge
%             edgeNum = 1;
%             edgeData(edgeNum, [1 2]) = edgeData(edgeNum, [2 1]);
%             g = graph.plotter.Graph.newNamedInstance(...
%                 'graph_reversed', ...
%                 edgeData, ...
%                 graph.plotter.MaxFlowFixture.LOCATION);
%             
%             obj.graphTest(g, 2.94, 3);
%         end
    end
    
    %=========================== PRIVATE METHODS =========================
    methods (Access = private)
        function graphTest(obj, g, figNum) %#ok<MANU>
            % A simple test of plotting a simple graph and the s-t potential
            % and current field for unit current.
            
            % Plot the graph
            plotter = graph.plotter.GraphPlotter(g, struct('radius', 20, 'fontSize', 12));
            figure(figNum); % figNum = figNum+1;
            plotter.plotNodes('color', 'k', 'FaceColor', 'w');
            plotter.plotEdges('color', 'k');
%             plotter.plotAggregates(struct('list', [1 3 6]), 'FaceColor', 'r', 'color', 'k');
%             plotter.plotAggregates(struct('list', [2 4 5]), 'FaceColor', 'g', 'color', 'k');
            shg;
%            save_figure('png', sprintf('%s_graph.png', g.metadata.name));
            
            % Plot Laplacian matrix weights
%             plotter.plotEdgeMatrix(g.laplacian);
%             shg;
%             save_figure('png', sprintf('%s_laplacian.png', g.metadata.name));
        end
    end
    
end
