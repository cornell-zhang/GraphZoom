function h = harmonics(dim, varargin)
%HARMONICS Frequency harmonics offset matrix.
%   H = HARMONICS(DIM, COLORS) returns a matrix whose I-th row corresponds
%   to the offset of the I-th harmonic from its base frequency undergoing a
%   COLORS-process in DIM dimensions. For example,
%
%   HARMONICS(2,2) = [[0,0]; [0,1]; [1,0]; [1,1]]
%
%   corresponding to ((T1,T2),(T1,T2+PI),(T1+PI,T2),(T1+PI,T2+PI)). The
%   harmonics offsets in each row are multiplied by PI to get a harmonic
%   frequency of the base frequency (T1,T2).
%
%   HARMONICS(DIM, MINCOLOR, MAXCOLOR) returns offsets between MINCOLOR and
%   MAXCOLOR. That is, HARMONICS(DIM, COLORS) = HARMONICS(DIM, 0,
%   COLORS-1). See also: NDGRID.

% Compute all base-COLORS numbers of length DIM usin NDGRID. This is the
% same as the coordinates of the vertices of DIM-dimensional cube of size
% COLORS in each direction. VERTEXCOORDINATE{D} holds the D-components of
% the coordinates of all vertices.

if (nargin == 2)
    minColor = 0;
    maxColor = varargin{1}-1;
elseif (nargin == 3)
    minColor = varargin{1};
    maxColor = varargin{2};
else
    error('Must specify 2 or 3 arguments');
end

c = minColor:maxColor;
if (dim == 1)
    h = c';
else
    numColors = numel(c);
    vertexCoordinate = cell(dim, 1);
    for d = 1:dim
        vertexCoordinate{d} = c;
    end
    hColumns = cell(dim, 1);
    [hColumns{:}] = ndgrid(vertexCoordinate{:});
    
    % Populate columns of H from vertex coordinates in reverse order of
    % HCOLUMNS because of the way NDGRID orders output arguments
    h = zeros(numColors^dim, d);
    for d = 1:dim
        h(:,d) = hColumns{dim-d+1}(:);
    end
end

end
