function result = isPositive(a)
%ISPOSITIVEINTEGRAL True for arrays with positive numeric elements.
%   ISPOSITIVEINTEGRAL(A) returns true if A is an array of positive numeric
%   elements and false otherwise.
%
%   Example:
%      isPositive([1 3]) returns true isPositiveIntegral ([0 3.5])
%      returns false isPositiveIntegral ([-1 3.5]) returns false
%
%   See also ISINTEGRAL, ISNUMERIC, ISFLOAT.

result = isnumeric(a) && isempty(find(a <= 0, 1));
