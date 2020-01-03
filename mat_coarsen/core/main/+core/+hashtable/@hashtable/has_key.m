function b = has_key(this, key)

% Return true if the hashtable contains the provided key, or false
% otherwise.

b = 0 ~= find_key(this, key);

