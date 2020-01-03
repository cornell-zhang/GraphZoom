function e = uv(d,i)
%UV Unit vector.
%   e = UV(D,I) is the d-dimensional ith unit vector, that is,
%   e is a 1xd vector of zero entries, except e(i)=1.
%   
%   See also ZEROS, EYE.

% Author: Oren Livne
%         06/21/2004    Version 1: Created

e           = zeros(1,d);
e(i)        = 1;
