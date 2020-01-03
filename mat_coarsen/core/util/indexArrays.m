function [i, a, colSize, first, last] = indexArrays(A)
%INDEXARRAYS Summary of this function goes here
%   Detailed explanation goes here

[i, dummy, a]   = find(A); %#ok
clear dummy;
colSize     = sum(spones(A));
first       = cumsum([1 colSize(1:end-1)]);
last        = first + colSize - 1;

end
