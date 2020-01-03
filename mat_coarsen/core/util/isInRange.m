function result = isInRange(a, low, high, border)
%ISINRANGE True for arrays with bounded-range elements.
%   ISINRANGE(A,LOW,HIGH) returns true if and only if LOW <= A <= HIGH.
%   Alternate syntax is ISINRANGE(A,LOW,HIGH,'closed')
%
%   ISINRANGE(A,LOW,HIGH,'open') returns true if and only if LOW < A <
%   HIGH.
%
%   ISINRANGE(A,LOW,HIGH,'open_closed') returns true if and only if LOW < A
%   <= HIGH.
%
%   ISINRANGE(A,LOW,HIGH,'closed_open') returns true if and only if LOW <= A
%   < HIGH.
%
%   Example:
%       isinrange([1 3], 1, 3, 'open') returns false
%       isinrange([1.1 3], 1, 3, 'open_closed') returns true
%       isinrange([1 3], 1, 3, 'closed_open') returns false
%       isinrange([1 3], 1, 3) returns true
%
%   See also ISNUMERIC, ISFLOAT.

if (nargin < 4)
    border = 'closed';
end

result = isnumeric(a);
switch (border)
    case 'open'
        result = result && isempty(find((a <= low) | (a >= high), 1));
    case 'open_closed'
        result = result && isempty(find((a <= low) | (a >  high), 1));
    case 'closed_open'
        result = result && isempty(find((a <  low) | (a >= high), 1));
    case 'closed'
        result = result && isempty(find((a <  low) | (a >  high), 1));
    otherwise
        error('ISINRANGE: Unsupported border type ''%s''', border);
end

