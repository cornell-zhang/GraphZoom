classdef (Sealed) GraphPlotter < handle
    %GRAPHPLOTTER A planar graph drawing.
    %   This class generates a 2-D drawing of a Graph object.
    %
    %   See also: GRAPH.
    
    %=========================== FIELDS ==================================
    properties (GetAccess = public, SetAccess = private)
    end
    properties (GetAccess = private, SetAccess = private)
        g                       % Graph to plot
        x                       % Node coordinates
        options                 % Plotting options
        textLocation            % Edge field text locations
        lineStart               % Edge lines start coordinates
        lineEnd                 % Edge lines end coordinates
    end
    
    %=========================== CONSTRUCTORS ============================
    methods
        function obj = GraphPlotter(g, varargin)
            %GraphPlotter Constructor.
            %   GraphPlotter(g, varargin) constructs a graph plotter of the
            %   graph g. varargin is parsed
            % into plotting options.
            
            % Mandatory arguments
            obj.g  = g;
            obj.x  = obj.g.coord;
            if (isempty(g.coord))
                error('Must set node coords to print a graph');
            end
            % Parse optional parameters
            opts        = graph.plotter.GraphPlotterOptions(varargin{:});
            obj.options = opts.build();
            
            obj.prepareFigure();
        end
    end
    
    %=========================== METHODS =================================
    methods
        function plotNodes(obj, varargin)
            % Plot an optional nodal function 'label' at the vertices of
            % the graph. If the option 'nodes' is specified, a subset off
            % the nodes is considered only. 'label' must be the same size
            % as 'nodes'.
            
            % Read options
            plotOpts    = struct(varargin{:});
            radius      = graph.plotter.GraphPlotter.getField(plotOpts, 'radius', obj.options.radius);
            textColor   = graph.plotter.GraphPlotter.getField(plotOpts, 'textColor', 'k');
            faceColor   = graph.plotter.GraphPlotter.getField(plotOpts, 'faceColor', obj.options.faceColor);
            edgeColor   = graph.plotter.GraphPlotter.getField(plotOpts, 'edgeColor', 'none');
            % Custom color list to delineate coarse aggregates. Overrides
            % faceColor.
            faceColors  = graph.plotter.GraphPlotter.getField(plotOpts, 'faceColors', []);
            
            % Prepare data
            n       = obj.g.numNodes;
            nodes   = graph.plotter.GraphPlotter.getField(plotOpts, 'nodes', 1:n);
            label   = graph.plotter.GraphPlotter.getField(plotOpts, 'label', ...
                nodes);
            if (obj.options.fontSize == 0)
                label = [];
            end     
            X = obj.x(nodes,:);
            
            % Plot a circle for each node
            circleArea = pi*radius^2;
            if (isempty(faceColors))
                % Uniform color for all nodes
                h = scatter(X(:,1), X(:,2), circleArea, faceColor, 'filled');
                %h.set('MarkerFaceColor', faceColor);
            else
                % Color each aggregate in a different color
                h = scatter(X(:,1), X(:,2), circleArea, faceColors, 'filled');
            end
            
            % Further stylize node plot
            if (~strcmp(edgeColor, 'none'))
                set(h, 'MarkerEdgeColor', edgeColor);
            end
            uistack(h, 'top');
            
            % Print circle labels
            if (~isempty(label))
                if (size(label, 1) == 1)
                    label = label';
                end
                if (isIntegral(label))
                    formatText = @(x)(sprintf('%d', x));
                else
                    formatText = @(x)(sprintf('%.3g', x));
                end
                strings = cellfun(formatText, mat2cell(label, ones(size(label))), 'UniformOutput', false);
                h = text(X(:,1), X(:,2), strings, 'HorizontalAlignment', 'center', ...
                    'color', textColor, 'FontSize', obj.options.fontSize);
                uistack(h, 'top');
            end
        end
        
        function h = plotEdges(obj, varargin)
            % Plot graph edges. graphType determines whether edges are
            % directed or not.
            plotOpts = struct(varargin{:});
            lineWidth = graph.plotter.GraphPlotter.getField(plotOpts, 'LineWidth', 0.5);
            
            % Prepare edge line coordinates
            obj.computeEdgeData();
            
            % Plot edges
            drawnow;
            if (obj.g.metadata.graphType == graph.api.GraphType.UNDIRECTED)
                h = line([obj.lineStart(:,1) obj.lineEnd(:,1)]',[obj.lineStart(:,2) obj.lineEnd(:,2)]');
                set(h, 'LineWidth', lineWidth, 'color', 'black');
                uistack(h, 'bottom');
            else
                % Directed graph, unoptimized code below -- slow
                for i = 1:obj.g.numEdges
                    if (mod(i,100) == 0)
                        fprintf('Printing edge %d\n', i);
                    end
                    arrowvec(obj.lineStart(i,:), obj.lineEnd(i,:), 'b');
                end
            end
        end
        
        function plotEdgeMatrix(obj, f)
            % Plot a sparse matrix f's entries on the edges of the graph.
            % graphType determines whether edges are directed or not. This
            % function also supports a full vector f of non-zeros defined
            % on the edges of the graph.
            
            % Prepare edge line coordinates
            obj.computeEdgeData();
            
            % Print appropriate entries at all edges
            textFormat  = @(x)(sprintf('%.2g', x));
            if (issparse(f))
                f = nonzeros(f);
            end
            fText   = cellfun(textFormat, mat2cell(f, ones(size(f))), 'UniformOutput', false);
            h       = text(obj.textLocation(:,1), obj.textLocation(:,2), fText);
            set(h, 'HorizontalAlignment', 'center');
            set(h, 'FontSize', obj.options.fontSize);
            set(h, 'FontWeight', obj.options.fontWeight);
        end
        
        function plotEdgeField(obj, f, varargin)
            % Plot a flow field f on the edges of the graph. graphType
            % determines whether edges are directed or not.
            
            % Prepare edge line coordinates
            obj.computeEdgeData();
            
            if (numel(varargin) >= 1)
                fieldType = varargin{1};
            else
                fieldType = 'none';
            end
            
            % Print function all edges
            switch (fieldType)
                case 'flow'
                    textFormat = @(x,y)(sprintf('%.4g / %.2g\n', x, y));
                    fText = arrayfun(textFormat, f, obj.g.weight, 'UniformOutput', false);
                otherwise
                    textFormat = @(x)(sprintf('%.3g\n', x));
                    fText = arrayfun(textFormat, f, 'UniformOutput', false);
            end
            numEdges = obj.g.numEdges;
            dx = 0;
            dy = 0;
            h = text(-0.03 + obj.textLocation(:,1) .* (1 + dx*2*(rand(numEdges,1)-1)), ...
                obj.textLocation(:,2) .* (1 + dy*2*(rand(numEdges,1)-1)), ...
                fText);
            set(h, 'FontSize', obj.options.fontSize);
            set(h, 'FontWeight', obj.options.fontWeight);
        end
        
        function plotFunctions(obj, p, f)
            % Plot the graph, a potential function p at the vertices, and a
            % flow field f on the edges.
            obj.plotNodeFunction(p, f, []);
        end
    end
    
    %=========================== GET & SET ===============================
    methods
    end
    
    %=========================== PRIVATE METHODS =========================
    methods (Access = private)
        function prepareFigure(obj)
            % Initialize figure; set axis to best fit the graph coord
            % region
            clf;
            hold on;
            
            alpha   = 1.3;
            limits  = [min(obj.x); max(obj.x)];
            limits  = [...
                0.5*((1+alpha)*limits(1,:) + (1-alpha)*limits(2,:)); ...
                0.5*((1-alpha)*limits(1,:) + (1+alpha)*limits(2,:)) ... 
                ];
%            axis image;
%            axis on;
%            limits = axis;
            xlim([limits(1) - 0.1 limits(2)+0.1]);
            ylim([limits(3) - 0.1 limits(4)+0.1]);
            axis equal;
            %             r = obj.options.radius; xlim(limits(:,1) +
            %             [-r;r]); ylim(limits(:,2) + [-r;r]);
        end
        
        function plotNode(obj, x, p, plotOpts)
            % Print and format p(x) at node x. color = text color. TODO:
            % make circles full white background to hide end of edges
            radius  = graph.plotter.GraphPlotter.getField(plotOpts, 'radius', obj.options.radius);
            color   = graph.plotter.GraphPlotter.getField(plotOpts, 'FaceColor', 'white');
            circle(x, radius, color);
            %set(h, 'FaceAlpha', 0.5);
            if (~isempty(p))
                obj.printText(x, sprintf('%.3g', p), plotOpts);
            end
        end
        
        function printText(obj, x, text, plotOpts)
            % Print and format text at coord x. color = text color.
            color = graph.plotter.GraphPlotter.getField(plotOpts, 'color', 'r');
            h = textvec(x, text, color);
            set(h, 'FontSize', obj.options.fontSize);
            set(h, 'FontWeight', obj.options.fontWeight);
        end
        
        function computeEdgeData(obj)
            % Plot graph edges. graphType determines whether edges are
            % directed or not.
            if (~isempty(obj.textLocation))
                % Fields are already cached
                return;
            end
            N = obj.g.edge;
            numEdges = obj.g.numEdges;
            coord = obj.g.coord;
            fr = obj.options.edgeFraction;
            
            % Prepare edge line coordinates
            %             if (obj.g.metadata.graphType ==
            %             graph.api.GraphType.UNDIRECTED)
            %                 n = numEdges/2;
            %             end
            obj.textLocation    = zeros(numEdges, 2);
            obj.lineStart       = zeros(numEdges, 2);
            obj.lineEnd         = zeros(numEdges, 2);
            count = 0;
            for i = 1:numEdges
                u       = N(i,1);
                v       = N(i,2);
                %                 if (obj.g.metadata.graphType ==
                %                 graph.api.GraphType.UNDIRECTED) && (u >
                %                 v)
                %                     continue;
                %                 end
                
                count = count + 1;
                xu      = coord(u,:);
                xv      = coord(v,:);
                %offset  = obj.options.radius/norm(xv-xu);
                offset = 0;
                xStart  = (1-offset)*xu + offset*xv;
                xEnd    = offset*xu + (1-offset)*xv;
                
                % Edge weight coord; slightly text offset nicely separates
                % the text from edge
                obj.textLocation(count,:)   = (1-fr)*xStart + fr*xEnd - [0.02 0];
                obj.lineStart(count,:)      = xStart;
                obj.lineEnd(count,:)        = xEnd;
            end
        end
    end
    
    methods (Static, Access = private)
        function value = getField(plotOpts, fieldName, defaultValue)
            % Get a value from the plotOpts struct, or fall back to
            % defaultValue.
            if (isfield(plotOpts, fieldName))
                value = plotOpts.(fieldName);
            else
                value = defaultValue;
            end
        end
    end
end
