function w = affinity2connection(c)
%AFFINITY2CONNECTION Convert affinity to algebraic connection stength.
%   W = AFFINITY2CONNECTION(C) returns W = 1./(1-C).
%
%   See also: AFFINITY_L2.

w = 1./(1-c);
w(c > 1-eps) = Inf;

end

