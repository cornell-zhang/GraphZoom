function results = graphWrite(g, group, name)
%GRAPHWRITE Write graph instance to file in MAT format.
%   RESULTS = GRAPHWRITE(G, GROUP, NAME) saves the graph G in the
%   GLOBAL_VARS.data_dir under group GROUP and name NAME within the
%   group.
%
%   See also: GRAPHPLOT, GRAPHCONVERT, PUMP, GLOBAL_VARS.

if (nargin ~= 3)
    error('Must specify a graph, group and name');
end

config;
global GLOBAL_VARS;

% Create a dummy batch reader for the graph
batchReader = graph.reader.BatchReader;
batchReader.add('graph', g);
g.metadata.group = group;
g.metadata.name = name;
g.metadata.attributes.g = g;

% Run data pump
outputDir       = GLOBAL_VARS.data_dir;
pump            = graph.runner.Pump(batchReader, outputDir, graph.runner.RunnerWriteMat(outputDir));
pump.maxEdges   = Inf;
results         = pump.run();
end
