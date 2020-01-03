function b = dilate_list(siz,a,n,filter)
%DILATE_LIST Dilate a list of flagged cells.
%   B = DILATE_LIST(SIZ,A) returns a "dilated image" of A (a convlution with a filter
%       that determines the local connections. This represents one "safety layer" on the binary array A of
%       flagged cells. This function is similar to DILATE, except that A is given in a form of a list d-dimensional indices,
%       and B is the list of indices of the dilated image. SIZ is the size of the entire domain,
%       to which B is limited (it is truncated if lies outside the domain).
%   B = DILATE_LIST(SIZ,A,N) dilates N times (N safety layers).
%   B = DILATE_LIST(SIZ,A,N,F) dilates N times with the filter F. F = 'star' is the star stencil
%   (5-point in 2D), F = 'box' is a box stencil (9-point in 2D). Default is F = 'star'.
%
%   See also DILATE.
 
% Author: Oren Livne
% Date  : 06/17/2004    Version 1: created.

if (nargin < 3)
    n = 1;                                                      % Default: one dilation layer
end
if (nargin < 4)
    filter  = 'star';                                           % Default is 5-point stencil (generalized to d-dim)
end

dim     = length(siz);                                          % Dimension of a

f       = zeros(0,dim);                                         % d-dimensional indices list (empty)
switch (filter)                                                 % Build filter
case 'box',
    f   = box_list(-ones(1,dim),ones(1,dim));                   % d-dimensional binary cube [-1,1]^d
case 'star',
    center  = zeros(1,dim);
    f       = [f; center];
    for d = 1:dim,
        nbhr    = center;
        nbhr(d) = 1;
        f       = [f; nbhr];
        nbhr(d) = -1;
        f       = [f; nbhr];
    end
end

b       = unique(a,'rows');                                     % Start with a

for i = 1:n                                                     % Dilate n times
    btemp   = [];
    bigb    = [];
    for d = 1:dim
        c = repmat(b(:,d),1,size(f,1))';
        bigb(:,d) = c(:);
    end
    btemp   = bigb + repmat(f,size(b,1),1);
    inside  = find(check_range(btemp,ones(1,dim),siz) > 0);
    btemp   = btemp(inside,:);
    b       = unique(btemp,'rows');
end
