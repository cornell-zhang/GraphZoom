function i = find_var(ind,lower,upper,start,sz)
%FIND_VAR 1D index of a d-D gridpoint in a lexicographically ordered
%   rectangular grid.
%
%   Usage: I = FIND_VAR(L,LOWER,UPPER,START,SZ)
%
%   Input:
%   ind = d-D coordinates (I1,I2,...) of the gridpoint in the range
%   [1..nx,1..ny,...]
%   lower = Lower bound for the indices in each dimension.
%   upper = Upper bound for the indices in each dimension.
%   start = Offset for the output 1D indices.
%   Output:
%   i = 1D lexicographic coordinate of the gridpoint (I1,I2,...)
%   in the d-D rectangular grid bounded by lower and upper.
%   ind=(0,0,...) corresponds to i=start.
%
%   See also REPMAT.

% Revision history:
% 11/18/2003    Oren Livne      Created
% 05/30/2004    Oren Livne      Changed comments, removed global_params so that this is a toolkit function.

[m,dim]     = size(ind);
i           = zeros(m,1);                               % ind is k x d; i will be k x 1
Low         = repmat(lower,m,1);
Up          = repmat(upper,m,1);
outside     = find(min((ind < Low) | (ind > Up),[],2));
good        = setdiff([1:m]',outside);
ngood       = size(good,1);
a           = ind(good,:)-repmat(start,ngood,1);        % Indices k x d, start = lower-left corner of the truncation region
b           = ones(ngood,1);                            % Start 1D indices from 1
factor      = 1;
for d = 1:dim,                                          % Compute 1D (lexicographically ordered) indices
    b       = b + factor*a(:,d);
    factor  = factor*sz(d);
end
i(good)     = b;
i(outside)  = -1;
