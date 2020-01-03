function n = floordiv(x, y)
%FLOORDIV Integral division for floating-point operands, rounding towards
%minus infinity.
%   n = FLOORDIV(x,y) is n = floor(x./y). Assuming y ~= 0.  If y is not an
%   integer and the quotient x./y is within roundoff error of an integer,
%   then n is that integer.  The inputs x and y must be real arrays of the
%   same size, or real scalars.
%
%   See also MOD, FLOOR.

tol = 10*eps;
n = x/y;
modulus = mod(x,y);
isIntegral = (abs(modulus) < tol) | (abs(modulus-y) < tol) | (abs(modulus+y) < tol);
integral = isIntegral & y;
n(integral) = round(n(integral));
nonIntegral = ~isIntegral & y;
n(nonIntegral) = floor(n(nonIntegral));
%fprintf('x = %.3e  y = %.3e  n = %.3e   x/y = %.3e\n', x, y, n, x./y);
