function results = graphRemoveOldMetadata(minEdges, maxEdges, inputDirs, outputDir, varargin)
%GRAPHREMOVEOLDMETADATA Remove large obsolete metadata from graph
%instances.
%   RESULTS = GRAPHREMOVEOLDMETADATA(MINEDGES, MAXEDGES, INPUTDIRS,
%   OUTPUTDIR, ...) removes METADATA.ATTRIBUTES.G from each graph instance
%   G found under a list INPUTDIRS of input directories under
%   GLOBALVARS.data_dir with at most MAXEDGES edges to MAT format, and
%   saves them under the output directory GLOBAL_VARS.data_dir/OUTPUTDIR.
%   The function returns a results struct with success/failure and other
%   information.
%
%   Note: the special input directory string DIR = 'uf' is not recognized
%   by this script.
%
%   See also: PUMP, GLOBAL_VARS.

config;
global GLOBAL_VARS;

% Read input arguments
args = parseArgs(minEdges, maxEdges, inputDirs, outputDir, varargin{:});

% Load graphs using a batch reader
fprintf('--- Loading graphs ---\n');
batchReader = graph.reader.BatchReader;
for directory = args.inputDirs
    dir = directory{1};
    batchReader.add('dir', [GLOBAL_VARS.data_dir '/' dir]);
end

% Run data pump
fprintf('--- Fixing graphs ---\n');
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
writer = graph.runner.RunnerRemoveOldMetadata(args.outputDir);
end
