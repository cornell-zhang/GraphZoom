function baseRepresentation = ind2base(d, b, n)
%IND2BASE Convert decimal integer to base-B representation.
%  IND2BASE(D,B) returns the representation
%   of a non-negative integer D as a integer in base B. IND2BASE(D,B,N)
%   produces a representation with at least N digits. If D is an array,
%   IND2BASE returns a matrix whose I-th row is the base-B representation
%   of D(I).
%
%   Examples
%           IND2BASE(23,3) returns [2 1 2]
%           IND2BASE(23,3,5) returns [0 0 2 1 2]
%           IND2BASE([1;23],3,5) returns [[0 0 0 0 1];[0 0 2 1 2]]
%
%   See also: BASE2IND, BASE2DEC, DEC2HEX, DEC2BIN.

% Argument validation and defaults
error(nargchk(2, 3, nargin,'struct'));
if (~isempty(find(d < 0, 1)) || ~isIntegral(d))
    error('MATLAB:ind2base:InvalidIndex', ...
        'The index must be a non-negative integer value');
end
if (nargin < 3)
    n = 1;
end

% Determine the maximum number of digits in the base representation
numDigits = max(n, ceil(logBase(max(d(:)), b)));

% Recursively divide to obtain representation digits
baseRepresentation = zeros(numel(d), numDigits);
for i = numDigits:-1:1
    digit = rem(d, b);
    baseRepresentation(:, i) = digit;
    d = (d - digit)/b;
end

end
