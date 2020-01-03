function d = affinity_l2(x, y)
%AFFINITY_L2 Affinity using the L2 norm.
%   D=AFFINITY_L2(X,Y) returns the L2-norm-based affinity
%   between node I and node set, J whose respective TV data are X and Y.
%
%   See also: CONNECTIONESTIMATORALGEBRAIC.

% Deal with the cases of i,j = vectors and i=scalar, j=vector
nRows       = size(y,1);
if (isvector(x))
    x = repmat(x, nRows, 1);
end
d = (sum(x.*y, 2)).^2 ./ (sum(x.*x, 2) .* sum(y.*y, 2));

end
