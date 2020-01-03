function val = get(this, key)

% Return the object stored in the table with key, or [] if no such key is
% found.

[i,j,val] = find_key(this, key);

