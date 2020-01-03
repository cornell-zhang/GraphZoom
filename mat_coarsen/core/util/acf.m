function mu = acf(history, a, b)
%ACF Asymptotic convergence factor (from convergence history).
%   MU = ACF(HISTORY) returns the estimated asymptotic convergence factor
%   from a convergence factory history array HISTORY.
%
%   MU = ACF(HISTORY,A,B) filters the history around its median by up to a
%   factor A (i.e. only values in [MEDIAN/A,A*MEDIAN] are considered), and
%   the ACF is a weighted sum whose weights are proportional to B^I, where
%   I is an index into the HISTORY array. A and B must be >= 1.
%
%   See also: MEDIAN, RUNNERACF.

error(nargchk(1,3,nargin,'struct'));

if (find(isinf(history) | isnan(history),1))
    %error('MATLAB:CoarseningState:acf', 'Encountered infinite/NaN convergence factor');
    mu = Inf;
    return;
end

if (nargin < 2)
    a = 2;
end
if (nargin < 3)
    b = 3; %1.5;
end
n       = numel(history);
%sampleSize = 20; % The sampleSize last iterations are used to base ACF estimate on
filterSize = min(floor(n/3), 10);  % Filtering up to filterSize-mode periodicity of the reduction factor

% Filter round-off effects and the atypical initial iterations
%n       = numel(history);
m       = median(history);
typical = find((history >= m/a) & (history <= a*m));

% ACF = weighted average of typical iteration convergence factors
weights = b.^(typical-n);  % So that weights always < 1 and don't blow up
%weights = b*typical;
weights = weights / sum(weights);
sample  = history(typical);
filteredSample = filter(ones(1,filterSize)/filterSize, [1 0], sample);
mu      = sum(weights .* filteredSample);

%mu
%mu      = median(history(typical));
%mu      = mean(history(typical));


%history
% %n = numel(typical);
% %s = max(1,n-sampleSize+1):n;
% sample = history(typical(s));
% filteredSample = filter(ones(1,filterSize)/filterSize, [1 0], sample);
% %mu = median(sample);
% mu = median(filteredSample);
% %mu = mean(filteredSample)
% 
% %mu      = mean(history(typical(end-10:end)));

end
