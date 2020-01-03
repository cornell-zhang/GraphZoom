function [in, out, cin, cout] = affinityInOut(setup, l, i)
%AFFINITIES Intra- and inter-affinities around a node.
%   [IN, OUT, CIN, COUT] = AFFINITYINOUT(SETUP, L, I) returns the
%   cross-affinity matrix CI among the associates IN of the level-(L+1)
%   aggregate to which node I belongs. COUT is the cross-affinity matrix
%   between IN and all associates OUT of the aggregate's neighboring
%   aggregates. That is, CIN is the aggregate's intra-affinity matrix, and
%   COUT its inter-affinity matrix.
%
%   (The cross-affinity matrix C of X,Y is a SIZE(X,2)-by-SIZE(Y,2) matrix
%   whose elements are C(I,J) = c(X(I,:),Y(J,:)).)
%
%   See also: AFFINITY_L2, AFFINITYCROSS.

% Useful aliases
level = setup.level{l};
A = level.A;
T = setup.level{l+1}.T;

% Compute neighbor sets
I = find(T(:,i));             % i's aggregate
in = find(T(I,:));            % I's associates
[out, dummy] = find(A(:,in)); %#ok
clear dummy;
out = setdiff(out, in);       % associates of I's neighbors

% Compute affinities
cin  = affinityCross(level, in, in);
cout = affinityCross(level, in, out);

% Print stats
fprintf('i=%d, aggregate I=%d, |in|=%d, |out|=%d\n', i, I, numel(in), numel(out));

[cinMin, index] = min(cin(:));
[k, l] = ind2sub(size(cin), index);
fprintf('Minimum intra-affinity: c(%d,%d) = %e\n', in(k), in(l), cinMin);

[coutMax, index] = max(cout(:));
[k, l] = ind2sub(size(cout), index);
fprintf('Maximum inter-affinity: c(%d,%d) = %e\n', in(k), out(l), coutMax);

end