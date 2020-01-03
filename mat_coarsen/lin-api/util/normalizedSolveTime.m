function t = normalizedSolveTime(tTotal, e, isIterative)
%NORMALIZEDSOLVETIME Normalized solver solve type.
%   T=normalizedSolveTime(TTOAL, E, ISITERATIVE) computes the normalized
%   solve time TTOTAL (per significant figure) of the method that
%   produced the error norm history E. he unnormalized solve time is
%   tTotal. The ISITERATIVE flag should be true for iterative solvers and
%   false for direct solvers.
%
%   T=normalizedSolveTime(TTOAL, E) is the same as
%   T=normalizedSolveTime(TTOAL, E, TRUE).
%
%   See also: RUNNERSOLVER, LOG10.

if (nargin < 3)
    isIterative = true;
end

% Normalize run time
if (~isIterative)
    % Direct solver - no history. Don't scale.
    t = tTotal;
elseif (isempty(e) || (e(1) == 0))
    t = 0;
elseif ((e(1) > 0) && (e(end) > e(1))) %(acf > 1) % Likely divergence
    t = Inf;
else
    totalReduction = log10(e(1)/(e(end)+eps)); % #orders of magnitudes in error reduction. More precise than acf^num_cycles for tCycle's computation
    t = tTotal / totalReduction;
end
end
