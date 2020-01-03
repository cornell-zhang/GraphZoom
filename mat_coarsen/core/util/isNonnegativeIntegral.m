function result = isNonnegativeIntegral(a)
%ISNONNEGATIVEINTEGRAL True for arrays with non-negative integer elements.
%   ISNONNEGATIVEINTEGRAL(A) returns true if A is an array of non-negative
%   integers and false otherwise. A's element type need not be an integer
%   data type.
%
%   Example:
%      isNonnegativeIntegral([1 3]) returns true isPositiveIntegral ([0 3])
%      returns true isPositiveIntegral ([-1 3]) returns false
%
%   See also ISINTEGRAL, ISNUMERIC, ISFLOAT.

result = isIntegral(a) && isempty(find(a < 0, 1));
