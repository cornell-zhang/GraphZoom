function val = ninterp(x,y,t)
%NINTERP Evaluate Lagrange interpolating polynomial
%   NINTERP(x,y,t) returns the value(s) of the Lagrange
%   interpolating polynomial for the points x and values
%   y, evaluated at t.  x and y must be vectors of the
%   same length and x must have distinct entries.  t may
%   be a scalar, vector, or matrix, and the returned value
%   is of the same size and shape.
%
%   NINTERP uses the Newton form of the Lagrange interpolating
%   polynomial.  In infinite precision arithmetic the result
%   of NINTERP(x,y,t) would be the same as that of
%   POLYVAL(POLYFIT(x,y,length(x)-1),t), but in finite precision
%   arithmetic, NINTERP can be much better.
%
%   See also: POLYFIT.

% Compute the divided differences to use as coefficients and
% evaluate the polynomial using nested evaluation.
y = divdif(x,y);
n = length(y);
val = y(n)*ones(size(t));
for i = n-1:-1:1
  val = val.*(t-x(i)) + y(i);
end

function y = divdif(x,y)
%DIVDIFF Compute divided difference vector
%
%       y = DIVDIF(x,y) returns a vector of divided differences
%       associated with the points x and values y.  x and y must be
%       vectors of the same length and x must have distinct entries.
%       The returned vector d is the sequence of divided differences of
%       order 0, 1, ...
%
%           y(1), (y(2)-y(1))/(x(2)-x(1)), ...
%
%       These divided differences are the coefficient of Newton's
%       form of the Lagrange interpolating polynomial, interpolating
%       the values y(i) and the points x(i).

n = length(x);
if n ~= length(y) 
  error('divdif:  sizes of input vectors must agree')
end
for i = 1:n-1
  for j=n:-1:i+1
    y(j) = (y(j) - y(j-1)) / (x(j) - x(j-i));
  end
end

