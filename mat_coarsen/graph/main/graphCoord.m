function coord = graphCoord(g, nodes)
%GRAPHCOORD Generate graph coordinates using SFDP.
%   C=GRAPHCOORD(G) generates 2-D coordinates for all nodes of the graph
%   G. C=GRAPHCOORD(G, NODES) generates 2-D coordinates for the subgraph of
%   G consisting of the nodes NODES.
%
%   You will need to install GRAPHVIZ (including the SFDP plotter). See
%   http://www.graphviz.org/Download..php for installation instructions.
%
%   GLOBAL_VARS must be set with the CONFIG command before this method can
%   be called.
%
%   See also: WRITERDOT, GraphType, CONFIG.

if (nargin < 2)
    %nodes = 1:g.numNodes;
    nodes = [];
end
    
% Convert g to a DOT file
writerFactory   = graph.writer.WriterFactory();
writerDot       = writerFactory.newInstance(graph.api.GraphFormat.DOT);
dotFile         = tempname;
writerDot.write(g, dotFile, 'nodes', nodes);

% Convert DOT file to a PLAIN file using the SFDP utility (a system call)
plainFile       = tempname;
status = system(['sfdp -q2 -T plain -Ksfdp -o"' plainFile '" ' ...
    dotFile]);
if (status ~= 0)
    error('MATLAB:plotGraph:sfdp', 'Failed to convert DOT to PLAIN file using the SFDP command');
end

% Read coordinates from file
coord = readGraphCoord(plainFile);

% Clean up
delete(dotFile);
delete(plainFile);

end
