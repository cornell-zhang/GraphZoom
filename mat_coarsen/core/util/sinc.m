function g = sinc(r)
%SINC Sinc kernel.
%   G(R) = SIN(R)/R.

%r = x-y;
g = sin(r)./r;
g(abs(r) <= eps) = 1;
