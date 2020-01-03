function this = increase_size(this)

% setup the new hash index array
while (this.numel + 1) / this.size > this.load
    this.size = ceil(this.size * this.grow);
end

this.index = sparse(this.size, this.size);

% rehash the entries
for k = 1:this.numel
    h = private_hash(this, this.hash(this.entries{k}.key));
    j = 1;
    while this.index(h,j) ~= 0
        j = j + 1;
    end
    this.index(h,j) = k;
end

% grow the entries cell array
maxidx = ceil(this.size * this.load);
this.entries{maxidx + 1} = [];


    