function [data,key,i] = sortAcfResults(r)
%SORTACFRESULTS Sort a cycle ACF result bundle by severity.
%   [DATA,KEY,I]=SORTACFRESULTS(PATH) sorts ResultBundle R by
%   slowest-and-largest -to- fastest-or-smallest graphs, and outputs a data
%   matrix. Each row is in the format
%
%       [numNodes numLevels tSetup tSolve #levels].
%
%   KEY is a cell array of problem keys corresponding to DATA rows. I is
%   the sorting index vector into the original result bundle.
%
%   See also: RUNCYCLEACF, RESULTBATCH.


% Retrieve [numNodes numLevels tSetup tSolve #levels]
data = [...
    cellfun(@(x)(x.numNodes), r.metadata) ...
    cellfun(@(x)(x.numEdges), r.metadata) ...
    r.data(:,r.fieldColumn('tSetup')) ...
    r.data(:,r.fieldColumn('tSolve')) ...
    r.data(:,r.fieldColumn('Levels'))...
    ];
key = cellfun(@(x)(x.key), r.metadata, 'UniformOutput', false);

% Sort by descending setup time, but also give precedence to the graph's
% size
%m = (max(data(:,2),eps)).^(1/3).*data(:,3);
m = data(:,3);
[dummy1, i] = sort(m, 'descend'); %#ok
data = [data(i,:) m(i)];
key  = key(i);

end

