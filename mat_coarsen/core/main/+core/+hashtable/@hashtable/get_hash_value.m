function k = get_hash_value(this, obj)

% Return the raw hash value for obj using the hashing function currently in
% use by hashtable this.

k = this.hash(obj);