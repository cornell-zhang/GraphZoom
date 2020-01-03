function num = numTrue(array)
%NUMTRUE Number of true elements in a boolean array.
%   NUM = NUMTRUE(ARRAY) returns the number of non-zero/true elements in
%   the array ARRAY.
%
%   See also: XOR, ANY.

num = numel(find(array));
end

