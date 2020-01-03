function n = numEntities(s)
%NUMENTITIES Return the number of entities in a space-delimited string.
%   S is assumed to be in the format [a1 .. an] where ai are integers.
%   Returns n.

r = regexp(s, '\D');
n = length(r)+1;

%n = numel(regexpi(s, ' '))+1; % slower

end
