function results = graphConvert(minEdges, maxEdges, inputDirs, outputDir, varargin)
%GRAPHCONVERT Convert graph instances to MAT format.
%   RESULTS = GRAPHCONVERT(MINEDGES, MAXEDGES, INPUTDIRS, OUTPUTDIR, ...)
%   converts all graph instances found under a list INPUTDIRS of input
%   directories under GLOBALVARS.data_dir with at most MAXEDGES edges to
%   MAT format, and saves them under the output directory
%   GLOBAL_VARS.data_dir/OUTPUTDIR. The function returns a results
%   struct with success/failure and other information.
%
%   Examples:
%       1) Save all graphs with 0 <= #edges <= 100 found under
%       GLOBALVARS.data_dir/input1 and GLOBALVARS.data_dir/input2 to
%       GLOBALVARS.data_dir/out/input1 and
%       GLOBALVARS.data_dir/out/input2, respectively:
%
%       results = graphConvert(0, 100, {'input1', 'input2'}, 'out');
%
%       2) Decompose all graphs into single components and save all
%       components with #nodes >= 3 (minSize = 2 by default)
%
%       results = graphConvert(0, Inf, {'input1', 'input2'}, 'out',
%       'filter', 'component-decompose', 'minSize', 3);
%
%   Note: the special input directory string DIR = 'uf' refers UF symmetric
%   undirected graph instances instead of to a physical directory.
%
%   See also: PUMP, GLOBAL_VARS.

config;
global GLOBAL_VARS;

% Read input arguments
args = parseArgs(minEdges, maxEdges, inputDirs, outputDir, varargin{:});

% Load graphs using a batch reader
batchReader = graph.reader.BatchReader;
for directory = args.inputDirs
    dir = directory{1};
    switch (dir)
        case 'uf'
            batchReader.add('formatType', graph.api.GraphFormat.UF, ...
                'type', graph.api.GraphType.UNDIRECTED);
        otherwise
            batchReader.add('dir', [GLOBAL_VARS.data_dir '/' dir]);
    end
end

% Run data pump
pump            = graph.runner.Pump(batchReader, args.outputDir, newWriter(args));
pump.minEdges   = minEdges;
pump.maxEdges   = maxEdges;
results         = pump.run();
end

%======================== PRIVATE METHODS =========================
function args = parseArgs(minEdges, maxEdges, inputDirs, outputDir, varargin)
% Parse input arguments.
global GLOBAL_VARS;

p                   = inputParser;
p.FunctionName      = 'graphConvert';
p.KeepUnmatched     = true;
p.StructExpand      = true;

p.addRequired('minEdges', @isPositiveIntegral);
p.addRequired('maxEdges', @isPositiveIntegral);
p.addRequired('inputDirs', @(x)(iscell(x) || ischar(x)));
p.addRequired('outputDir', @ischar);
p.addParamValue('minSize', 2, @(x)(isPositiveIntegral(x) && (x >= 2)));
p.addParamValue('filter', 'none', @(x)(any(strcmp(x, {'none', 'component-decompose'}))));

p.parse(minEdges, maxEdges, inputDirs, outputDir, varargin{:});
args = p.Results;

% Remove trailing slash in output dir string
args.outputDir       = [GLOBAL_VARS.data_dir '/' args.outputDir];
if (args.outputDir(end) == '/')
    args.outputDir = args.outputDir(1:end-1);
end

% Single input directory => convert to a cell array
if (ischar(args.inputDirs))
    args.inputDirs = {args.inputDirs};
end
end

%--------------------------------------------------------------------
function writer = newWriter(args)
% A factory method to instantiate the appropriate graph writer.
switch (args.filter)
    case 'none',
        writer = graph.runner.RunnerWriteMat(args.outputDir);
    case 'component-decompose',
        writer = graph.runner.RunnerComponentDecomp(args.outputDir);
        writer.minSize = args.minSize;
end
end
