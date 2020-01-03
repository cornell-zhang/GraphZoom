function b = cascade(a,filter)
%CASCSDE Dilate a binary image of flagged cells into a "cascaded form".
%   B = CASCADE(A) returns a "cascaded dilated image" of A (a convlution with a filter
%   that determines the local connections. We use a 5-point filter in 2D, 7-point in 3D).
%   Instead of 1's in A, B contains in those cells the number of A-neighbours of such an A-cell.
%   (CASCADE(A)>0) is the standard dilation operator (one "safety layer") on the binary A.
%
%   See also CONV2, TEST_CASE, TEST_MOVEMENT.
 
% Author: Oren Livne
% Date  : 05/27/2004    Version 1: created and added comments.
% Date  : 06/04/2004    Generalized to d-dimensions, added filter options

if (nargin < 2)
    filter = 'star';                                            % Default is 5-point stencil (generalized to d-dim)
end

n       = size(a);                                              % Size of a in all direction
dim     = length(n);                                            % Dimension of a

switch (filter)
case 'box',
    f = ones(3*ones(1,dim));                                    % d-dimensional box of size 3x...x3
case 'star',
    f = zeros(3*ones(1,dim));                                   % d-dimensional box of size 3x...x3
    ind                     = 2*ones(1,dim);
    s                       = num2cell(ind);
    f(s{:})                 = 1;                                % Center point
    for d = 1:dim,
        ind                 = 2*ones(1,dim);
        ind(d)              = 1;
        s                   = num2cell(ind);
        f(s{:})             = 1;                                % Direction-d left-neighour
        ind(d)              = 3;
        s                   = num2cell(ind);
        f(s{:})             = 1;                                % Direction-d right-neighour
    end
end

bbig    = convn(a,f);                                           % Convolve A with the filter, so bbig is replaced by the sum of neighouring 1's, neighbours specified by f
frame   = cell(dim,1);                                            % The convolution makes a bigger b than we need. Throw the extra layers of bbig that envelope the indices of the original a
for d = 1:dim,
    frame{d} = size(f,d)-1 + (0:size(a,d)-1);
end
b       = bbig(frame{:});                                       % Extract the relevant frame from b so that size(b)=size(a)
