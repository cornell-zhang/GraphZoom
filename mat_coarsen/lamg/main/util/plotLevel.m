function coord = plotLevel(setup, l, varargin)
%PLOTLEVEL Plot a level in a multi-level setup using our GraphPlotter.
%   COORD=PLOTLEVEL(SETUP, L, ...) generates a plot of SETUP.LEVEL{L}'s graph
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
config;
args        = parseArgs(varargin{:});
fineLevel   = setup.level{l};
%n           = fineLevel.size;
g           = fineLevel.g;
plotArgs    = {'textColor', 'k', 'edgeColor', 'k', 'fontSize', args.fontSize};
if (isempty(args.nodes))
    args.nodes = 1:g.numNodes;
end
g = g.subgraph(args.nodes);
plotArgs = [plotArgs, {'label', args.nodes}];
if ((l < setup.numLevels) && args.coarsening)
    coarseLevel = setup.level{l+1};
else
    args.coarsening = false;
end

% Create working copy of fine-level graph
gw       = Graphs.fromAdjacency(g.adjacency);
%gw.coord = fineLevel.coord; % Default to level-provided coordinates
if (~isempty(args.coord))
    gw.coord = args.coord;
elseif (~isempty(fineLevel.g.coord))
    gw.coord = fineLevel.g.coord(args.nodes,:);
elseif (~isempty(fineLevel.coord))
    gw.coord = fineLevel.coord(args.nodes,:);
else
    gw.coord = graphCoord(g); % Fall back to graph drawing package coordinate computation
end
coord = gw.coord;

% Generate random aggregate colors. Choose colors that are not too dark.
if (args.coarsening && ~coarseLevel.state.details.isElimination)
    [i, dummy]  = find(coarseLevel.T(:,args.nodes));
    clear dummy;
    aggIndex    = unique(i);
    nc          = numel(aggIndex);
    stream      = RandStream.getGlobalStream;
    setRandomSeed(1);
    c           = 0.2*repmat([1 1 1], nc, 1) + 0.8*rand(nc, 3);
    RandStream.setGlobalStream(stream);
    [colorIndex, dummy] = find(coarseLevel.T(aggIndex,args.nodes)); %#ok
    c           = c(colorIndex,:);
    plotArgs    = [plotArgs, {'faceColors', c}];
end

% Plot the graph
opts        = optionsOverride(struct('label', []), struct(varargin{:}));
plotter     = graph.plotter.GraphPlotter(gw, opts);
plotter.plotNodes(plotArgs{:});
plotter.plotEdges('LineWidth', 1);

% Plot affinities
if (args.affinity)
    f = affinityCross(fineLevel, args.nodes, args.nodes);
    c = f(find(tril(gw.adjacency))); %#ok
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
p.addParamValue('nodes', [], @isnumeric);
p.addParamValue('coord', [], @isnumeric); % overrides g.coord field

p.addParamValue('radius', 10, @isPositive);
p.addParamValue('edgeFraction', 0.5, @(x)((x >= 0) && (x <= 1)));
p.addParamValue('fontSize', 8, @isNonnegativeIntegral);
p.addParamValue('fontWeight', 'normal', @(x)(isempty(x) || any(strcmpi(x,{'plain', 'bold', 'italic'}))));
p.addParamValue('faceColor', [0.8 0.8 0.8], @(x)(ischar(x) || isnumeric(x)));
p.addParamValue('edgeColor', [0.8 0.8 0.8], @(x)(ischar(x) || isnumeric(x)));

p.parse(varargin{:});
args = p.Results;
end
