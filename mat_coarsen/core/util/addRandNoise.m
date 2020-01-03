function y = addRandNoise(x, a, varargin)
%ADDRANDNOISE Add a uniformly distributed noise to a quantity.
%   ADDRANDNOISE(X,A) adds random noise with relative error A to X. More
%   precisely, Y = X .* RANDINRANGE(1,1+2*A,SIZE(X)).
%
%   See also: RAND, RANDINRANGE.

%==========================================================================

%y = x .* randInRange(1, 1+2*a, size(x));
y = x .* randInRange(1-a, 1+a, size(x));
