function gNew = trimProblemFlow(g, sz)
%TRIMPROBLEMFLOW Trim the Koutis flow problem to a smaller grid size.
%   GNEW = TRIMPROBLEMFLOW(G,SZ) trims the number of gridpoints in the x
%   direction to SZ.
%
%   See also: SUB2INDUNCHECKED.

% Load problem
A            = g.adjacency;
[i, j, a]    = find(A);
n            = g.numNodes;

% Reverse-engineere grid indices
N            = [1638 40];
Ntotal       = prod(N);
nConstraints = n - Ntotal;
k            = cell(2,1);
index        = (1:Ntotal)';
[k{:}]       = ind2sub(N, index);
k            = [k{:}];

% Construct a mapping of old gridpoint index -> new gridpoint index
NNew        = [sz N(2)];
NtotalNew   = prod(NNew);
nNew        = NtotalNew + nConstraints;
leftMargin  = floor(sz/2);
rightMargin = N(1) - (sz - leftMargin) + 1;
cut         = rightMargin - leftMargin - 1;
kx          = k(:,1);
kNew        = k;
% This will assign the gridpoints cut from the middle of the x domain
% negative indices in kNew
kNew((kx > leftMargin) & (kx < rightMargin),:) = 0;
kNew(kx >= rightMargin, 1) = kNew(kx >= rightMargin, 1) - cut;
kNew        = num2cell(kNew, 1);
% Append non-grid (constraint) nodes to mapping. They map to themselves.
indexNew    = [sub2indunchecked(NNew, kNew{:}); (NtotalNew+1:nNew)'];

% Apply mapping to non-zero list. Remove negative indices, which are the
% gridpoints we removed
nzNew       = [indexNew(i), indexNew(j), a];
nzNew(min(nzNew(:,1:2),[],2) < 0,:) = [];
ANew        = sparse(nzNew(:,1), nzNew(:,2), nzNew(:,3), nNew, nNew);
gNew        = Graphs.fromAdjacency(ANew+ANew');

% Add spatial coordinates
k = cell(2,1);
[k{:}] = ind2sub([sz 40],(1:NtotalNew)');
gNew.coord = [k{:}; [zeros(nConstraints,1) (1:nConstraints)']];
