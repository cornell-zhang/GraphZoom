function f = smoothcauchy(x)
%SMOOTHCAUCHY Cauchy function.
%   F = SMOOTHCAUCHY(X) returns the infinitely differentiable but not
%   analytic Cauchy function F = EXP(-X.^(-2)).
%
%   See also SMOOTHHUMP, SMOOTHSTEP.
 
% Author: Oren Livne
% Date  : 06/23/2004    Added comments.

f = exp(-x.^(-2));
