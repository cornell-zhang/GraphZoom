function k = private_hash(this, d)

% private hash function: hash a double value to an int in the range of our
% indices.

phi = 1.6180339887;

k = floor(abs(mod(d * phi,1) * this.size + 1));

