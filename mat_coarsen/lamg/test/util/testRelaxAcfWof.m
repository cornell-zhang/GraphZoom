function [stats, batchReader] = testRelaxAcfWof(dir, varargin)
%testRelaxAcfWof Compute ACF and WOF for GS relaxation in a batch run.
%   [STATS, READER] = RELAXACF(DIR, OPTIONS) prints a table of several
%   relaxation schemes' ACF statistics for all graph instances under the
%   directory DIR relative to the GLOBAL_VARS.DATA_DIR dir. OPTIONS
%   contains some more print options (e.g. minEdges, maxEdges =
%   minimum/maximum number of edges in considered graphs. Default=0/3000.
%   format = 'text'/'html' determines the printout format. totalWidth =
%   hint to total table width in the relevant measuring unit =
%   pixels/characters/...). READER is the batch reader used for reading
%   DIR; you may obtain an individual graph instance using a READER.READ()
%   call.
%
%   See also: GRAPHSTATS, RELAX, ACF.

config;
global GLOBAL_VARS;
% Can in principle be cached for all calls of this method
PRINTER_FACTORY     = graph.printer.PrinterFactory;
BATCH_RUNNER        = graph.runner.BatchRunner;

% Read input arguments
options = parseArgs(varargin{:});

% Load graphs using a batch reader
batchReader = graph.reader.BatchReader;
batchReader.add('dir', [GLOBAL_VARS.data_dir '/' dir]);
selectedGraphs = graph.api.GraphUtil.getGraphsWithEdgesBetween(...
    batchReader, options.minEdges, options.maxEdges);
if (~isempty(options.selectedIndices))
    selectedGraphs = selectedGraphs(options.selectedIndices);
    fprintf('Restricting runs to indices %d\n', selectedGraphs);
end

% Compute GS relaxation indices in a batch run
relax           = amg.relax.RelaxFactory('relaxType', 'gs');
runner          = RunnerRelaxAcfWof('laplacian', relax);
stats           = BATCH_RUNNER.run(batchReader, runner, selectedGraphs);

% Sort results by descending ACF
stats.sortRows(-stats.fieldColumn('ACF'));

% Print results to standard output (fid=1)
printer         = PRINTER_FACTORY.newInstance(options.format, stats, 1);
if (~isempty(options.totalWidth))
    printer.totalWidth = options.totalWidth;
end
printer.addIndexColumn('#', 3);
acfPrecision    = options.precision;
acfWidth        = max(11, acfPrecision + 6);
printer.addColumn('Group'   , 's', 'field'   , 'metadata.key',          'width', 28);
printer.addColumn('#Nodes'  , 'd', 'field'   , 'metadata.numNodes',   	'width',  7);
printer.addColumn('#Edges'  , 'd', 'field'   , 'metadata.numEdges',   	'width',  7);
printer.addColumn('ACF'     , 's', 'function', @(x,data,z)(formatAcf(data(1), acfPrecision)), 'width',  acfWidth);
printer.addColumn('WOF(1)'  , 'f', 'field'   , 'data(2)',             	'width',  7, 'precision', options.precision);
printer.addColumn('WOF(2)'  , 'f', 'field'   , 'data(3)',             	'width',  7, 'precision', options.precision);
printer.addColumn('WOF(3)'  , 'f', 'field'   , 'data(4)',             	'width',  7, 'precision', options.precision);
printer.addColumn('Min'     , 's', 'function', @(x,y,z)(formatAcf(bestIndex(x,y,z), acfPrecision)), 'width',  acfWidth);
printer.run();
end

%======================== PRIVATE METHODS =========================
function args = parseArgs(varargin)
% Parse input arguments.
p                   = inputParser;
p.FunctionName      = 'relaxAcfComparison';
p.KeepUnmatched     = true;
p.StructExpand      = true;

p.addParamValue('format', 'text', @(x)(any(strcmp(x, {'text', 'html'}))));
p.addParamValue('totalWidth', [], @isNonnegativeIntegral);
p.addParamValue('precision', 3, @isnumeric);
p.addParamValue('minEdges', 0, @isnumeric);
p.addParamValue('maxEdges', 3000, @isnumeric);
p.addParamValue('selectedIndices', [], @isnumeric);

p.parse(varargin{:});
args = p.Results;
end

function worst = bestIndex(dummy1, data, dummy2) %#ok
% Schema string corresponding to the best ACF.
worst = min(data);
end
