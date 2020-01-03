function i = find_label(s,label)
%FIND_LABEL  Return the first instance of a string in a label array.
%   This function returns the index of first instance of the label LABEL in the
%   label array (cell array of strings) S. If label is not found, we
%   return -1 and print a warning.
%
%   Input:
%   s = cell array of strings (label array).
%   label = label string sought.
%   Output:
%   ind = index of label in s (if label not found, i = -1).
%
%   See also FIND.

% Revision history:
% 05/30/2004    Oren Livne      Changed to a toolkit function.

i = -1;
for j = 1:length(s)
    if (length(s{j}) == length(label))
        if (s{j} == label)
            i = j;
            break;
        end
    end
end
if (i == -1)
    warning(sprintf('Label ''%s'' not found!',specie));
end
