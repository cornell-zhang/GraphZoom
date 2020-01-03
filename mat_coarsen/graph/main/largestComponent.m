function h = largestComponent(g)
%LARGESTCOMPONENT Return the largest component of an undirected graph.
%   H=largestComponent(G) returns the largest component sub-graph of the
%   graph G.
%
%   See also: COMPONENTS;

s           = components(g.adjacency);
m           = max(s);
if (m == 1)
    h = g;
else
    component   = argmax(hist(s,m));
    nodes       = find(s == component);
    h           = g.subgraph(nodes, sprintf('component-%d', component)); %#ok
end
end
