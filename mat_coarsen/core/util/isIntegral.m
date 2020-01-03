function result = isIntegral(a)
%ISINTEGRAL True for arrays with integer elements.
%   ISINTEGRAL(A) returns true if A is an array of integers and false
%   otherwise. A's element type need not be an integer data type.
%
%   Example:
%      isintegral(int8(3)) returns true because int8 is a valid integer
%      data type isintegral (3) returns true even though the constant 3 is
%      actually a double
%
%   See also ISINTEGER, ISNUMERIC, ISFLOAT.

result = isempty(find(abs(a - round(a)) >= eps, 1));
