function [acf,details] = twoLevelAcf(setup, numLevels, levels, cycleIndexTwoLevel, maxDirectSolverSize, varargin)
%TWOLEVELACF Two-level ACF at all levels of a multilevel setup.
%   ACF = TWOLEVELACF(SETUP,NUMLEVELS,LEVELS,CYCLEINDEXTWOLEVEL,MAXDIRECTSOLVERSIZE,...)
%   estimates the 2-level ACF at each level and returns it in a vector.
%
%   See also: TESTCYCLEACFATLEVEL.

L = setup.numLevels;
acf = zeros(L,1);
if (nargin < 2)
    numLevels = 2;
end
if (nargin < 3)
    levels = L-1:-1:1;
end
if (nargin < 4)
    cycleIndexTwoLevel = [];
end
if (nargin < 5)
    maxDirectSolverSize = [];
end

for l = levels
    if (isempty(maxDirectSolverSize))
        L = min(l+numLevels-1, setup.numLevels);
        sz = setup.level{L}.g.numNodes+1;
    else
        numLevels = setup.numLevels;
        sz = maxDirectSolverSize;
    end
    %     if (setup.level{L}.size > maxDirectSolverSize)
    %         fprintf('two level cycle index = %f\n', cycleIndexTwoLevel);
    %     else
    %         fprintf('Direct coarsest solver\n');
    %     end
    args = {'cycleDirectSolver', true, 'maxDirectSolverSize', sz, ...
        'cycleIndexTwoLevel', cycleIndexTwoLevel};
    [data, details] = testCycleAtLevel(setup, l, ...
        'cycleNumLevels', numLevels, args{:}, varargin{:});
    acf(l) = data(2);
end

end
