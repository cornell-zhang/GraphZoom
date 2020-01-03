function [acf, t] = testRandomSeed(g, maxAcf, seeds, varargin)
%TESTRANDOMSEED test with different random seeds.
%   [ACF, SEED] = TESTRANDOMSEED(G, MAXACF, SEEDS, ...) tests cycle ACF for
%   each of the elements of a random seed list SEED. If ACF > MAXACF, the
%   program breaks and returns the ACF vector (for all seeds processed) and
%   the offending random seed SEED. One can specify a variable argument
%   list for TESTCYCLEACF.
%
%   See also: TESTCYCLEACF.

%g = Graphs.testInstance('uf/Pajek/GD97_b'); g =
%Graphs.testInstance('ml/GD97_b/level-2'); g =
%Graphs.testInstance('ml/ilya/web-stanford/l11/level-21'); g =
%Graphs.testInstance(key);

% Find the random seed that triggers the problem
S = seeds;
t = [];
j = [];
acf = zeros(size(S));
for i = 1:numel(S)
    s = S(i);
    result = Solvers.runSolvers('graph', g, 'solvers', {'lamg'}, varargin{:}, 'randomSeed', s, 'tvNum', 12);
    acf(i) = result.details{1}.acf;
    if (acf(i) > maxAcf)
        t = s;
        j = i;
        break;
    end
end
if (~isempty(t))
    fprintf('Problem for random seed = %d  ACF = %d\n', t, acf(j));
end
end
