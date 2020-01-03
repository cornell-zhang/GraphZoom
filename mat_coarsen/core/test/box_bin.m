function b = box_bin(dim,base)
%BOX_BIN D-dimensional binary box - list of indices.
%   B = BOX_BIN(D) All possible 2^D combinations of 0's and 1's (binary sequences between 0 and 2^D-1).
%     This is a list representation of the D-dimensional binary cube [0,1]x...x[0,1].
%   B = BOX_BIN(D,BASE) does the same but for base BASE (i.e. the cube [0,BASE-1]x...x[0,BASE-1]).
%
%   See also BOX_LIST, DEC2BASE.
 
% Author: Oren Livne
% Date  : 06/18/2004    Version 1: created.

if (nargin < 2)
    base = 2;
end

bb                  = dec2base(0:base^dim-1,base,dim);      % Prepare binary/base combinations for boundary (last) cells
b                   = zeros(base^dim,dim);
for i = 1:base^dim,
    for d = 1:dim,
        b(i,d) = bb(i,d)-'0';
    end
end
