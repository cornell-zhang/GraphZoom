function sz = box_size(r)
%BOX_SIZE Size of a box.
%   VOL = BOX_SIZE(R) returns the box size (in all dimensions) of a d-dimensional box R, specified
%   by its lower-left and upper-right corner coordinates. If R is a kx(2*d) array of
%   boxes, VOL will be a kxd array of their respective sizes.
%
%   See also BOX_INTERSECT, BOX_VOLUME, CREATE_CLUSTER..
 
% Author: Oren Livne
% Date  : 05/27/2004    Version 1: created and added comments.
% Date  : 06/04/2004    Adapted [x h] box convention
 
dim         = size(r,2)/2;                                      % Dimension of the problem
sz          = r(:,dim+1:2*dim);                                 % r = [x1 ... xd h1 ... hd] is a box [x1,x1+h1-1] x ... x [xd,xd+hd-1]
