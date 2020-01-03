function f = smoothhump(x,a,b)
%SMOOTHHUMP Infinitely differentiable finitely supported function.
%   F = SMOOTHHUMP(X,A,B) returns an infinitely differentiable
%   function F(X) whose support is [A,B]. It is symmetric around X=(A+B)/2
%   and its maximum is 1. X,A,B can be N-D vectors.
%
%   See also SMOOTHCAUCHY, SMOOTHSTEP.
 
% Author: Oren Livne
% Date  : 06/23/2004    Added comments.

z = (x-a)./(b-a);
f = exp(8 - z.^(-2) - (z-1).^(-2));
