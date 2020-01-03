function s = strconcatdelim(delimiter, varargin)
%STRCONCATDELIM Concatenate strings horizontally with a delimiter.
%   S = STRCONCATDELIMFIND(DELIMITER,S1,...,SN) concatenates the strings
%   with a delimiter.
%
%   Examples
%       strconcatdelim('/','a','b','c')     returns 'a/b/c'
%       strconcatdelim('/','a/', 'b')       returns 'a//b'
%
%       See also: STRCAT, STRREAD.

if (isempty(varargin))
    s = [];
    return;
end

% Build a cell array that looks like {'a', delimiter, 'b', delimiter, 'c'}
parts           = varargin;
delimiterParts  = repmat({delimiter}, size(parts));
allParts        = [parts; delimiterParts];
allParts        = allParts(1:end-1); % Remove trailing delimiter cell

s = strcat(allParts{:});
end
