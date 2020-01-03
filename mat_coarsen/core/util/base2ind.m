function d = base2ind(baseRepresentation, b)
%BASE2IND Convert base-B representation to a decimal number.
%   BASE2IND(D,B) returns the decimal (base-10) equivalent of a base-B
%   representation B. If B is a matrix, BASE2IND returns a vector whose
%   I-th element is the decimal representation of the I-th row of B. of
%
%   Examples
%           BASE2IND([[0 0 0 0 1];[0 0 2 1 2]], 3) returns [1;23]
%
%   See also: IND2BASE, DEC2BASE.

% Argument validation and defaults
error(nargchk(2, 2, nargin,'struct'));
% if (~isempty(find(baseRepresentation < 0, 1)) || ...
%         ~isempty(find(baseRepresentation >= b, 1)) || ...
%         ~isIntegral(baseRepresentation))
if (~isIntegral(baseRepresentation))
    error('MATLAB:ind2base:InvalidBaseRepresentation', ...
        'The elements of the base representation must be integers between 0 and %d', b-1);
end

% Horner's rule to compute d = sum_{i=1}^n baseRepresentation(i)*b^(n-i)
d = baseRepresentation(:,1);
for i = 2:size(baseRepresentation,2)
    d = b*d + baseRepresentation(:,i);
end

end
