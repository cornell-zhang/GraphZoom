function found = strfindany(text, varargin)
%UFFIND Find a string from a list within another.
%   FOUND = STRFIND(TEXT,PATTERN1,...,PATTERNN) returns 1 if at least one of the pattern
%   strings PATTERN1,...,PATERNN is found in string TEXT, otherwise 0.
%
%   Examples
%       s = 'How much wood would a woodchuck chuck?';
%       strfindany(s,'a')     returns 1 
%       strfindany(s,'a','s') returns 1
%       strfindany(s,'t','s') returns 0
%
%       See also: STRCMP, STRFIND, STRFINDALL.

found = 0;
for i = 1:numel(varargin)
    if (~isempty(strfind(text, varargin{i})))
        found = 1;
        break;
    end
end

end
