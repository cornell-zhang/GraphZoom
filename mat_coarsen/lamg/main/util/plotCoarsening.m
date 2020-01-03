function h = plotCoarsening(W, status, varargin)
%PLOTLEVEL Plot a level in a multi-level setup.
%   H = PLOTLEVEL(SETUP, O, ...) generates a plot of SETUP.LEVEL{L}'s graph
%   using the GRAPHVIZ4MATLAB package.
%
%   Extra plotting options include:
%
%   'coarsening'    Show the next coarse level's aggregates by
%                   assigning each aggregate's associates a different nodal
%                   color.
%
%   'nodeSize'      Size of node circles. Default: 0.08.
%
%   See also: GRAPHVIZ4MATLAB, SETUP, LEVEL, CYCLE.

% Aliases
args    = parseArgs(varargin{:});
n       = size(W,1);

% Build arguments for fine-level graph plot
plotArgs = {'-adjMat', W, '-undirected', true};

% Generate random aggregate colors and assign them to the corresponding
% associate nodes
stat        = status;
seeds       = find(stat == 0);
stat(seeds) = seeds;
numSeeds    = numel(seeds);
stat(stat < 0) = n+1;  % Dummy aggregate that leads to undecided nodes color = last row of c below

aggregateIndexFine        = zeros(1,n+1);
aggregateIndexFine(seeds) = 1:numel(seeds);
aggregateIndexFine(n+1)   = numSeeds+1;
aggregateIndex = aggregateIndexFine(stat);

% Choose colors that are not too dark
c = [0.2*repmat([1 1 1], numSeeds, 1) + 0.8*rand(numSeeds, 3); [1 1 1]];
C = mat2cell(c(aggregateIndex,:), ones(n,1), 3*ones(1,1));
plotArgs = [plotArgs, {'-nodeColors', C}];

% Plot graph, set plot options
h = graphViz4Matlab(plotArgs{:});
h.setNodeSize(args.nodeSize);

end

%======================== PRIVATE METHODS =========================
function args = parseArgs(varargin)
% Parse input arguments.
p                   = inputParser;
p.FunctionName      = 'plotCoarsening';
p.KeepUnmatched     = true;
p.StructExpand      = true;

%p.addParamValue('format', 'text', @(x)(any(strcmp(x, {'text', 'html'}))));
p.addParamValue('nodeSize', 0.08, @isPositive);

p.parse(varargin{:});
args = p.Results;
end
