function coord = plotGraph(g, varargin)
%PLOTGRAPH Plot a graph using our GraphPlotter.
%   COORD=PLOTGRAPH(G, L, ...) generates a plot of the graph G
%   using the GraphPlotter class. GraphViz is used to generate 2-D node
%   coordinates.
%
%   Extra plotting options include:
%
%   'nodes'         Plot only the sub-graph of this node set.
%
%   'coarsening'    Show the next coarse level's aggregates by
%                   assigning each aggregate's associates a different nodal
%                   color.
%
%   'radius'        Size of node circles. Default: 0.08.
%
%   See also: GRAPHVIZ4MATLAB, SETUP, LEVEL, CYCLE.

% Set up, aliases
args        = parseArgs(varargin{:});
plotArgs    = {'textColor', 'k', 'edgeColor', 'k', 'fontSize', args.FontSize};
if (isempty(args.nodes))
    args.nodes = 1:g.numNodes;
end
g = g.subgraph(args.nodes);
plotArgs = [plotArgs, {'label', args.nodes}];
args.coarsening = false;

% Create working copy of fine-level graph
gw       = Graphs.fromAdjacency(g.adjacency);
%gw.coord = fineLevel.coord; % Default to level-provided coordinates
if (~isempty(args.coord))
    gw.coord = args.coord;
elseif (~isempty(g.coord))
    gw.coord = g.coord;
else
    gw.coord = graphCoord(g); % Fall back to graph drawing package coordinate computation
end
if (args.flipLr)
    gw.coord(:,1) = -gw.coord(:,1);
end
if (args.flipUd)
    gw.coord(:,2) = -gw.coord(:,2);
end

% Plot the graph
opts        = optionsOverride(struct('label', []), struct(varargin{:}));
plotter     = graph.plotter.GraphPlotter(gw, opts);
if (args.radius > 0)
    plotter.plotNodes(plotArgs{:});
end
plotter.plotEdges('LineWidth', 1);

% Plot affinities
if (args.affinity)
    f = affinityCross(fineLevel, args.nodes, args.nodes);
    c = f(find(gw.adjacency)); %#ok
    %c = sqrt(c./max(1-c,eps));
    plotter.plotEdgeField(c);
end
end

%======================== PRIVATE METHODS =========================
function args = parseArgs(varargin)
% Parse input arguments.
p                   = inputParser;
p.FunctionName      = 'plotLevel';
p.KeepUnmatched     = true;
p.StructExpand      = true;

%p.addParamValue('format', 'text', @(x)(any(strcmp(x, {'text', 'html'}))));
p.addParamValue('affinity', false, @islogical);
p.addParamValue('coarsening', false, @islogical);
p.addParamValue('radius', 20, @isNonnegativeIntegral);
p.addParamValue('nodes', [], @isnumeric);
p.addParamValue('FontSize', 8, @isNonnegativeIntegral);
p.addParamValue('coord', [], @isnumeric); % overrides g.coord field
p.addParamValue('flipUd', false, @islogical);
p.addParamValue('flipLr', false, @islogical);

p.parse(varargin{:});
args = p.Results;
end
