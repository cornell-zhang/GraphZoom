function [keys, vals] = dump(this)

% Retrieve all keys and corresponding values (in no particular order).

keys = cell(this.numel, 1);
vals = cell(this.numel, 1);

for i = 1:this.numel
    keys{i} = this.entries{i}.key;
    vals{i} = this.entries{i}.value;
end

