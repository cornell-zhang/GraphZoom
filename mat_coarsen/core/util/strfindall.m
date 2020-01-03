function found = strfindall(text, varargin)
%STRFINDALL Find all strings within another.
%   FOUND = STRFIND(TEXT,PATTERN1,...,PATTERNN) returns 1 if all pattern
%   strings PATTERN1,...,PATERNN are found in string TEXT, otherwise 0.
%
%   Examples
%       s = 'How much wood would a woodchuck chuck?';
%       strfindall(s,'a')     returns 1 
%       strfindall(s,'a','s') returns 0
%       strfindall(s,'t','s') returns 0
%
%       See also: STRCMP, STRFIND.

found = 1;
for i = 1:numel(varargin)
    if (isempty(strfind(text, varargin{i})))
        found = 0;
        break;
    end
end

end
