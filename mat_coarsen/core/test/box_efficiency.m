function efficiency = box_efficiency(points,rect)
%BOX_EFFICIENCY Box efficiency of covering flagged cells.
%   EFFICIENCY = BOX_EFFICIENCY(POINTS,RECT) returns the efficiency of the box RECT
%   of covering the flagged cells POINTS. POINTS is a binary image, and RECT is described
%   by the d-dimensional box convention [x1 ... xd h1 ... hd], where x is the lower-left corner cell 
%   and h is the size of the box. RECT is assumed to be contained in
%   the scope of POINTS. If RECT is kx(2*d), EFFICIENCY is a kx1 vector of the efficiencies
%   of each box (here efficiency = number of points in box / area of box).
% 
%   See also BOX_SIZE, BOX_VOLUME, CREATE_CLUSTER.

% Author: Oren Livne
% Date  : 05/27/2004    Version 1: handles RECT kx4 arrays, not just a single box
% Date  : 06/04/2004    Generalized to d-dimensions and adapted [x h] box convention

n           = size(rect,1);                                     % Number of boxes in this collection
dim         = size(rect,2)/2;                                   % Dimension of the problem
efficiency  = zeros(n,1);

for k = 1:n,
    r               = rect(k,:);                                % Box coordinates
    ind             = cell(dim,1);
    for d = 1:dim
        ind{d}      = num2cell(r(d):r(d)+r(d+dim)-1);           % Range of box in the d-dimension
    end
    s               = points(ind{:});                           % Flag data of this box
    sz              = box_size(r);                              % Vector containing the size of the box: [size_x,size_y]
    efficiency(k)   = length(find(s))/prod(sz);                 % Percentage of flagged cells in s
end
