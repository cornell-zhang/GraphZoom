function result = isPositiveIntegral(a)
%ISPOSITIVEINTEGRAL True for arrays with positive integer elements.
%   ISPOSITIVEINTEGRAL(A) returns true if A is an array of positive
%   integers and false otherwise. A's element type need not be an integer
%   data type.
%
%   Example:
%      isPositiveIntegral([1 3]) returns true isPositiveIntegral ([0 3])
%      returns false isPositiveIntegral ([-1 3]) returns false
%
%   See also ISINTEGRAL, ISNUMERIC, ISFLOAT.

result = isIntegral(a) && isempty(find(a <= 0, 1));
