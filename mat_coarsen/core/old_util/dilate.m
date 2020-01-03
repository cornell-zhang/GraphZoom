function b = dilate(a,n)
%DILATE Dilate a binary image of flagged cells.
%   B = DILATE(A) returns a "dilated image" of A (a convlution with a filter
%       that determines the local connections. We use a 5-point filter in 2D, 7-point in 3D).
%       This represents one "safety layer" on the binary array A of flagged cells.
%   B = DILATE(A,N) dilates N times (N safety layers).
%
%   See also CASCADE.
 
% Author: Oren Livne
% Date  : 05/27/2004    Version 1: created and added comments.

if (nargin < 2)
    n = 1;                                                      % Default: one dilation layer
end

b       = a;                                                    % Start with a
for i = 1:n                                                     % Dilate n times
    b       = (cascade(b) > 0);                                 % Whatever is non-zero is written back as 1
end
