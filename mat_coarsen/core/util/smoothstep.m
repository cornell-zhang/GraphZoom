function f = smoothstep(x,a,b,k)
%SMOOTHSTEP Smooth step/transition function.
%   F = SMOOTHSTEP(X,A,B,K) is an infinitely differentiable function that satisfies
%   F(X<=A)=-1, F(X>=B)=1, F monotone and anti-symmetric around X=(A+B)/2. K is the "bandwidth"
%   of F. A higher K means a steeper slope from F=-1 to F=1, near X=(A+B)/2. X can be a vector.
% 
%   See also ERFC.

% Author: Oren Livne
% Date  : 05/27/2004    Version 1: handles RECT kx4 arrays, not just a single box
% Date  : 06/04/2004    Generalized to d-dimensions and adapted [x h] box convention
if (nargin < 4)
   k = 1;
end
z = 2*(x-a)./(b-a) - 1;
center = find((-1 < z) & (z < 1));
f = zeros(size(z));
f(center) = erf(k*2*z(center)./(1-z(center).^2));
f(z <= -1) = -1;
f(z >=  1) =  1;

