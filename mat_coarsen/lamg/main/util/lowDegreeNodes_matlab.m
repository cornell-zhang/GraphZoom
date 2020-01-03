function [z,f,c] = lowDegreeNodes_matlab(A, d, maxDegree)
%LOWDEGREENODES Identify low degree graph nodes to be eliminated (pure
%MATLAB implementation).
%   [Z,F,C]=LOWDEGREENODES(A,D,MAXDEGREE) returns the indices of 0-degree
%   nodes (Z), (<=MAXDEGREE)-degree nodes (F) and the rest of the nodes (C)
%   in a symmetric adjacency matrix A. All F nodes are independent of each
%   other (i.e. A(F,F) is diagonal). D is a vector of node degrees; if
%   empty, it is internally set to SUM(SPONES(A)).
%
%   [Z,F,C]=LOWDEGREENODES(A) is equivalent to [Z,F,C]=LOWDEGREENODES(A,3).
%
%   See also: CoarseningStrategyLowImpact, amd.

if (nargin < 2)
    maxDegree = 3;
end
%MAX_DEGREE_UNCHECKED = 4; %3; % Maximum degree for which nbhr-nbhr
%connections are not checked. <=3 does not increase #edges. 4 means we
%might increase #edges by at most 50%.

% Initializations
if ((nargin < 2) || isempty(d))
    d = sum(spones(A));
end
z           = find(~d)';  % 0-degree nodes
candidate   = find((d > 0) & (d <= maxDegree));

% visited flag notation: 0 Not visited yet 1     0-degree node 2     low
% degree node (degree <= 3) 3     Not a candidate for elimination
ZERO_DEGREE     = 1;
HIGH_DEGREE     = 2;
LOW_DEGREE      = 3;
NOT_ELIMINATED  = 4;

% if (maxDegree > 3)              % Save memory - use W only if needed
%     W = tril(A);                % Adjacency matrix
% end
n                   = size(A,1);
visited             = HIGH_DEGREE * ones(n,1);
visited(z)          = ZERO_DEGREE;
visited(candidate)  = 0;         % Reset all relevant nodes to "not visited"
for i = candidate
    if (~visited(i))            % i hasn't yet been visited
        nbhrs   = find(A(:,i));
        %        if (degree == 0)
        %            % No neighbors = 0-degree node visited(i) =
        %            ZERO_DEGREE;
        %    elseif
        % no neighbors check
        if (isempty(find(visited(nbhrs) == LOW_DEGREE, 1)))
            % check neighbors
            %         if (isempty(find(visited(nbhrs) == LOW_DEGREE, 1)) &&
            %         ...
            %                 ((degree <= MAX_DEGREE_UNCHECKED) ||
            %                 (numel(find(W(nbhrs,nbhrs))) <= degree)))
            % A node whose elimination does not [much] increase the number
            % of A-edges, and which does not depend on another candidate
            % ==> candidate for elimination
            visited(i) = LOW_DEGREE;            % Low degree node (1-maxDegree)
            visited(nbhrs) = NOT_ELIMINATED;    % Now neighbors can't be candidates
        else
            % All other nodes
            visited(i) = NOT_ELIMINATED;
        end
    end
end

% Prepare output
%z = find(visited == ZERO_DEGREE);
if (nargout >= 2)
    f = find(visited == LOW_DEGREE);
end
if (nargout >= 3)
    c  = find((visited == NOT_ELIMINATED) | (visited == HIGH_DEGREE));
end

end
