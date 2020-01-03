function [stats, batchReader] = graphStats(dir, varargin)
%GRAPHSTATS Print graph statistics.
%   [STATS, READER] = GRAPHSTATS(DIR, OPTIONS) prints a table of graph
%   statistics for all graph instances under the directory DIR relative to
%   the GLOBAL_VARS.DATA_DIR dir. OPTIONS contains some more print options
%   (e.g. format = 'text'/'html' determines the printout format.
%   totalWidth = hint to total table width in the relevant measuring unit =
%   pixels/characters/...). READER is the batch reader used for reading
%   DIR; you may obtain an individual graph instance using a READER.READ()
%   call.
%
%   See also: PRINTER, READER.

config;
global GLOBAL_VARS;

% Read input arguments
options = parseArgs(varargin{:});

% Can in principle be cached for all calls of this method
batchRunner     = graph.runner.BatchRunner;
printerFactory  = graph.printer.PrinterFactory;

% Load graphs using a batch reader
batchReader = graph.reader.BatchReader;
batchReader.add('dir', [GLOBAL_VARS.data_dir '/' dir]);

% Create graph statistics table
runner = graph.runner.RunnerSimpleStats;
stats   = batchRunner.run(batchReader, runner);
% Sort results
stats.sortRows(stats.fieldColumn('numEdges'));

% Print results to standard output (fid=1)
printer = printerFactory.newInstance(options.format, stats, 1);
if (~isempty(options.totalWidth))
    printer.totalWidth = options.totalWidth;
end
printer.addIndexColumn('#', 3);
printer.addColumn('Group'       , 's', 'field'   , 'metadata.group',        'width', 37);
printer.addColumn('Name'        , 's', 'field'   , 'metadata.name',       	'width', 20);
printer.addColumn('#Nodes'      , 'd', 'field'   , 'metadata.numNodes',   	'width',  9);
printer.addColumn('#Edges'      , 'd', 'field'   , 'data(1)',             	'width', 10);
printer.addColumn('Description' , 's', 'field'   , 'metadata.description',  'width', 20);
printer.run();

end

%======================== PRIVATE METHODS =========================
function args = parseArgs(varargin)
% Parse input arguments.
p                   = inputParser;
p.FunctionName      = 'graphStats';
p.KeepUnmatched     = true;
p.StructExpand      = true;

p.addParamValue('format', 'text', @(x)(any(strcmp(x, {'text', 'html'}))));
p.addParamValue('totalWidth', [], @isNonnegativeIntegral);

p.parse(varargin{:});
args = p.Results;
end