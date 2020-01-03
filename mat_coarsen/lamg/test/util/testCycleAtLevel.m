function [data, details] = testCycleAtLevel(setup, finest, varargin)
%testCycleAtLevel Compute multi-level cycle ACF at an intermediate level.
%   [STATS, DETAILS] = RELAXACF(SETUP, FINEST, ...) computes the cycle ACF
%   at level FINEST of the multilevel hierarchy SETUP. VARARGIN can be used
%   to specify additional options.
%
%   See also: TESTCYCLEACF, RUNNERACF.

% Initializations
args = parseArgs(varargin{:});
mlOptions   = amg.api.Options.fromStruct(defaultOptions(), varargin{:});
acfComputer = lin.api.AcfComputer(...
    'initialGuessNorm', mlOptions.initialGuessNorm, ...
    'maxIterations', mlOptions.numCycles, ...
    'errorReductionTol', mlOptions.errorReductionTol, ...
    'logLevel', mlOptions.logLevel, ...
    'removeZeroModes', 'none', ...
    'combinedIterates', mlOptions.combinedIterates, ...
    'errorNorm', @errorNormResidual, ...
    varargin{:});
lev             = setup.level{finest};

% Create the relevant cycle and compute its ACF
tStart          = tic;

% Set a two-level cycle index. If empty, clear this option and
% use the default cycle index of the setup object.
cycleIndex      = setup.cycleIndex;
if (~isempty(args.cycleIndexTwoLevel))
    %cycleIndex(setup.finestHcrLevel) = args.cycleIndexTwoLevel;
    cycleIndex(finest+1) = args.cycleIndexTwoLevel;
end
setRandomSeed(now);
%b               = rand(lev.g.numNodes,1); b = b-mean(b);
b = zeros(lev.g.numNodes, 1);
%b([1 2]) = [1 -1];
cycle           = amg.solve.SolverLamgLaplacian.solveCycle(setup, b, mlOptions, ...
    'cycleIndex', cycleIndex, 'finest', finest);
problemAtLevel  = Problems.laplacian(lev.toGraph, b);
[acf, details]  = acfComputer.run(problemAtLevel, cycle);
tCycle          = toc(tStart);

% Save stats
hcr     = -1; %setup.hcr(finest);
work    = sum(setup.work(finest:end))*(setup.nodes(1)/setup.nodes(finest));
beta    = acf^(1/work);
e       = details.stats.errorNormHistory;
reductionPerIter = log10(e(1)/e(end)); % Number of orders of magnitudes in error reduction. More precise than acf^num_cycles for tCycle's computation
data = [mlOptions.nuDefault ...
    acf ...
    setup.nodeComplexity ...
    setup.edgeComplexity ...
    work ...
    hcr ...
    beta ...
    tCycle / (problemAtLevel.g.numEdges * reductionPerIter) ...
    ];

if (args.print)
    fprintf('Level %2d: ACF = %.3f\n', finest, acf);
%     fprintf('Level %d: nu = %d, HCR = %.3f, ACF = %.3f, Work = %.2f, beta = %.3f\n', ...
%         finest, mlOptions.nuDefault, hcr, acf, work, beta);
end
end

%======================== PRIVATE METHODS =========================
function mlOptions = defaultOptions()
% Standard Multi-level options for an ACF experiment. Default
% multilevel mlOptions.
mlOptions = amg.api.Options;

% Debugging flags
mlOptions.logLevel                  = 1;

% Multi-level cycle
mlOptions.cycleDirectSolver         = true;
end

%------------------------------------------------------------------
function args = parseArgs(varargin)
% Parse input arguments.
p                   = inputParser;
p.FunctionName      = 'testCycleAtLevel';
p.KeepUnmatched     = true;
p.StructExpand      = true;

p.addParamValue('cycleIndexTwoLevel', [], @isPositive);
p.addParamValue('print', true, @islogical);

p.parse(varargin{:});
args = p.Results;
end
