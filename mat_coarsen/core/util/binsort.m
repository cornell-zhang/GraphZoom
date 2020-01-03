function bins = binsort(x, n)
%BINSORT Simulate sorting by binning.
%   BINS=BINSORT(X,N) breaks the vector X down to N bins. Each bin has a
%   range of x values: the range [MIN(X),MAX(X)] is sub-divided into N
%   equidistant intervals (bins). BINS is an Nx1 cell array of the
%   corresponding X-sub-vector indices, i.e., BINS{I} = FIND(X >= LOW(I) &
%   X < HIGH(I)) where the Ith interval is [LOW(I),HIGH(i)). (An exception
%   is the last interval, which is closed.)
%
%   Example of usage:
%       >> x = rand(100,1); >> bins = binsort(x,10); >> sum(cellfun(@numel,
%       bins))   (returns 100)
%
%   See also: sort.

bins = cell(n, 1);
xMin = min(x);
xMax = max(x);

if (abs(xMax-xMin) < 1e-15)
    bins{1} = find(x);
else
    limits  = linspace(xMin, xMax, n+1);
    for i = 1:n-1
        bins{i} = find((x >= limits(i)) & (x < limits(i+1)));
    end
    i = n;
    bins{i} = find((x >= limits(i)) & (x <= limits(i+1)));
    
end
end
