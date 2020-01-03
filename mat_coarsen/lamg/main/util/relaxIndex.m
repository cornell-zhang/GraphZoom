function [acf, details] = relaxIndex(g, relaxType, indexType, varargin)
%RELAXACF Compute a relaxation method index for a single graph.
%   [ACF,DETAILS] = RELAXACF(G, RELAXTYPE, INDEXTYPE, OPTIONS) computes the
%   ACF of the relaxation scheme type RELAXTYPE (with optional construction
%   arguments passed via the OPTIONS struct). INDEXTYPE is the type of
%   index
%to compute (currently 'acf' and 'wof' are supported). DETAILS contains
%additional
%   information on the run (e.g. convergence history).
%
%   See also: GRAPHSTATS, RELAX, ACF.

% Read input arguments
options = parseArgs(relaxType, indexType, varargin{:});

% Relaxation scheme
relax           = amg.relax.RelaxFactory('relaxType', options.relaxType, varargin{:});

% Compute relaxation index
indexComputer   = newIndexComputer(options.indexType, varargin{:});
runner          = amg.runner.RunnerMethod(indexComputer, 'laplacian', indexType, relax);
[acf, details]  = runner.run(g);

end

%======================== PRIVATE METHODS =========================
function args = parseArgs(relaxType, indexType, varargin)
% Parse input arguments.
p                   = inputParser;
p.FunctionName      = 'relaxAcf';
p.KeepUnmatched     = true;
p.StructExpand      = true;

p.addRequired  ('relaxType', @(x)(any(strcmp(x,{'gs', 'jacobi'}))));
p.addRequired  ('indexType', @(x)(any(strcmp(x,{'acf', 'wof'}))));
p.addParamValue('debug', false, @islogical);

p.parse(relaxType, indexType, varargin{:});
args = p.Results;
end

function instance = newIndexComputer(indexType, varargin)
% Returns a new index computer instance.

switch (indexType)
    case 'acf'
        % Asymptotic convergence factor
        instance     = lin.api.AcfComputer(varargin{:});
    case 'wof'
        % Wipe-off factor
        instance     = amg.runner.WofComputer(varargin{:});
    otherwise
        error('MATLAB:relaxIndex:newIndexComputer:InputArg', 'Unknown relaxation index type ''%s''', indexType);
end
end
