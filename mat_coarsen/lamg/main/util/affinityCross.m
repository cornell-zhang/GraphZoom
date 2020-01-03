function c = affinityCross(input, i, j)
%AFFINITYCROSS Cross-affinity matrix.
%   C = AFFINITYCROSS(LEVEL, I, J) returns the affinities among X(I,:) and
%   X(J,:), where X = TVs at level L of the level object LEVEL.
%
%   C a SIZE(X,2)-by-SIZE(Y,2) matrix whose elements are C(I,J) =
%   c(X(I,:),Y(J,:)).
%
%   This function is not an efficient computation, and suitable mostly for
%   small X,Y.
%
%   C = AFFINITYCROSS(X, I, J) uses X as TVs instead of a level's TVs.
%
%   See also: AFFINITY_L2.

if (nargin < 3)
    j = i;
end

% Aliases
if (isa(input, 'amg.level.Level'))
    X = input.x;
else
    X = input;
end
x = X(i,:);
y = X(j,:);
nx = size(x,1);
ny = size(y,1);

% Compute one row of the affinity matrix at a time
if (ny > nx)
    c = zeros(ny,nx);
    for i = 1:nx
        c(:,i) = affinity_l2(x(i,:), y);
    end
    c = c';
else
    % Compute one column of the affinity matrix at a time
    c = zeros(nx,ny);
    for j = 1:ny
        c(:,j) = affinity_l2(y(j,:), x);
    end
end

end
