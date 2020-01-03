function vol = box_volume(r)
%BOX_VOLUME Volume of a box.
%   VOL = BOX_VOLUME(R) returns the box volume of a d-dimensional box R, specified
%   by its lower-left and upper-right corner coordinates. If R is a kx(2d) array of
%   boxes, VOL will be a kx1 array of their respective volumes.
%   RN(k,:) is extended so that the minimum side length is at least MIN_SIDE.
%   It is assumed that RN is a (possibly partial) partition of an original box R,
%   and we keep sure that after extending the RN-boxes, we shift them back so
%   that they are still contained in R.
%
%   See also BOX_INTERSECT, BOX_SIZE.   

% Author: Oren Livne
% Date  : 05/27/2004    Version 1: created and added comments. 

sz          = box_size(r);                                      % Rectangle side lengths
vol         = prod(sz,2);                                       % Total volume
