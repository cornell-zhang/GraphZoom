function this = put(this, key, val)

% store the object val indexed by key; if val is omitted, then the key is
% stored along with an empty val ([]), allowing you to use this as as a set
% data structure (use has_key() to test for set membership)
% 

if nargin < 3; val = []; end

[i,j] = find_key(this, key);


if i == 0
    if (this.numel + 1) / this.size > this.load
        this = increase_size(this);
    end
    this.numel = this.numel + 1;
    i = private_hash(this, this.hash(key));
    j = 1;
    while this.index(i,j) ~= 0
        j = j + 1;
    end
    this.index(i,j) = this.numel;
end

entry.key = key;
entry.value = val;

this.entries{this.index(i,j)} = entry;
    