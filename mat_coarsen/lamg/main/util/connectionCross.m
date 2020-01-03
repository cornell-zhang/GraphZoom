function d = connectionCross(level, i, j)
%AFFINITYCROSS Cross-algebraic-connection-strength matrix.
%   W = DISTANCECROSS(LEVEL, I, J) returns the algebraic connection
%   strengths among X(I,:) and X(J,:), where X = TVs at level L of the
%   level object LEVEL.
%
%   W a SIZE(X,2)-by-SIZE(Y,2) matrix whose elements are W(I,J) =
%   w(X(I,:),Y(J,:)), where w(x,y) is the connection strength between x and
%   y computed using TV affinities.
%
%   This function is not an efficient computation, and suitable for small
%   X,Y only. It is faster when |J| is larger than |I|.
%
%   See also: AFFINITY_CROSS.

d = affinity2connection(affinityCross(level, i, j));
end

