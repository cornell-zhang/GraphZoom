%AGGREGATIONSWEEP Aggregation sweep.
% [x, x2, stat, aggregateSize, numAggregates] = aggregationSweep(bins, x,
% x2, stat, aggregateSize, numAggregates, C, D, W, ratioMax,
% maxCoarseningRatio) loops over bins of undecided nodes and aggregates
% nodes. The TVs arrays x, x2 (=x.^2) and the aggregation arrays stat,
% aggregateSize, numAggregates are updated and returned from this function.
%
%   see also: CoarseSetAffinityEnergyModular.
