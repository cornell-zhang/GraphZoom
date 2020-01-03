function [in,out,cin,cout] = plotBadNode(s,k,u)
%PLOTBADNODE Plot a bad fine-level node u in a setup s's level k.

[in,out,cin,cout] = affinityInOut(s,k,u);
if (numel(in)==1)
    nodes = [in; out];
else
    nodes = [in out];
end
figure(1);
clf;
plotLevel(s, 1, 'radius', 15, 'nodes', nodes, 'FontSize', 8, ...
    'coarsening', true, 'affinity', true);shg
title(sprintf('Bad node u=%d', u));
end
