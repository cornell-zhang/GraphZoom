function mu = reductionPerIter(history, n)
%REDUCTIONPERITER Estimated asymptotic convergence factor from convergence
%history.
%   MU = REDUCTIONPERITER(HISTORY,N) returns the estimated asymptotic
%   convergence factor from a convergence factory history array HISTORY. It
%   filters out the first n iterations.  MU = REDUCTIONPERITER(HISTORY)
%   uses N=0.
%
%   This is good for a jumpy convergence factor.
%
%   See also: MEDIAN, RUNNERACF, ACF.

error(nargchk(1,2,nargin,'struct'));

if (find(isinf(history) | isnan(history),1))
    %error('MATLAB:CoarseningState:acf', 'Encountered infinite/NaN
    %convergence factor');
    mu = Inf;
    return;
end

if (nargin < 2)
    n = 0;
end

if (isempty(history))
    mu = Inf;
else
    k  = numel(history);
    if (k <= n+1)
        % Short history, use all iterations
        n = 0;
    end
    % Ignore the first n iterations
    mu = (history(k)/(history(n+1)+eps))^(1/(k-n-1));
end
end
