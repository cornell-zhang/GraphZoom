function [i,j,val] = find_key(this, key)

% find the index of key, if in this hashtable.
% If not in the table, then i will be zero and j will store the next
% available index in the hash entry.

h = private_hash(this, this.hash(key));

i = 0;
if nargout >= 3
    val = [];
end

j = 1;
idx = this.index(h,j);
while idx ~= 0
    entry = this.entries{idx};
    if this.equals(key, entry.key)
        i = h;
        if nargout >= 3
            val = entry.value;
        end
        break;
    end
    j = j + 1;
    idx = this.index(h,j);
end
