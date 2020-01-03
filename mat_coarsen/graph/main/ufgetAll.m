function ufgetAll(minEdges, maxEdges)
%UFGETALL Download the entire UF undirected graph collection.
%   This example script gets the index file of the UF sparse matrix collection,
%   and then download all problems marked as undirected graphs.
%
%   See also: UFGET, UFGET_EXAMPLE.

if (nargin < 1)
    minEdges = 0;
end
if (nargin < 2)
    maxEdges = Inf;
end

% Get the most recent index
[dummy, logger] = logging_config; %#ok
clear dummy;
logger('graph') = 'TRACE'; %#ok
ufget('refresh');

batchReader = graph.reader.BatchReader;
% Only undirected graphs
% batchReader.add('formatType', graph.api.GraphFormat.UF, ...
%     'type', graph.api.GraphType.UNDIRECTED, ...
%     'keywords', {'undirected', 'graph'});
% All symmetric problems
batchReader.add('formatType', graph.api.GraphFormat.UF, ...
    'type', graph.api.GraphType.UNDIRECTED);

fprintf('Loading %d problems, please wait ...\n', batchReader.size);
sortedGraphs = graph.api.GraphUtil.getGraphsWithEdgesBetween(batchReader, minEdges, maxEdges);
numGraphs = numel(sortedGraphs);
for i = 1:numel(sortedGraphs)
    g = batchReader.read(sortedGraphs(i));
    %[dummy, sv] = memory;
    %mem = sv.PhysicalMemory.Available/10^9;
    fprintf('[%5d/%d] Loaded %s/%s, size=%d/%d\n', ...
        i, numGraphs, ...
        g.metadata.group, g.metadata.name, ...
        g.numNodes, g.numEdges);
    clear g; % Save on memory
end

% % Load all matrices
% %f = find(strcmp(index.Group, 'SNAP'))';
% f = find (index.numerical_symmetry == 1);
% [y, j] = sort (index.nrows (f)) ;
% f = f (j) ;
% 
% for i = f
%     fprintf ('Loading %s%s%s, please wait ...\n', ...
%         index.Group {i}, filesep, index.Name {i}) ;
%     Problem = ufget (i,index) ;
%     disp (Problem) ;
%     clear Problem; % Save on memory
% end
% 
end