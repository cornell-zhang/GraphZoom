function result = matches(str, regex)
%MATCHES match string against a list of regular expressions.
%   MATCHES(STR, REGEX) returns true if and onlf if STR matches one of the
%   regular expressions in the cell array REGEX. If REGEX is empty, this
%   function returns true.

if (isempty(regex))
    result = true;
    return;
end
for i = 1:numel(regex)
    %    fprintf('Matching %s for regexp %s\n',str,regex{i});
    if (~isempty(regexp(str, regex{i}, 'ONCE')))
        result = true;
        return;
    end
end
result = false;

