function y = componentSpan(A)
%COMPONENTSPAN Laplacian null-space span.
%   Y=COMPONENTSPAN(A) returns a matrix whose columns span the null-space
%   of the graph laplacian (or symmetric adjacency matrix) A.
%
%   See also: COMPONENTS, AUGMENTEDLAPLACIAN.

c = components(A)';
n = numel(c);
numComponents = max(c);
if (numComponents == 1)
    % Singly-connected graph
    y = spones(ones(n,1));
else
    % Multiply-connected graph: construct the augmented A's non-zero list
    nzList          = zeros(n, 3);
    index           = 0;
    currentRow      = 0;
    for i = 1:numComponents
        index           = index+1;
        component       = find(c == i);
        componentSize   = numel(component);
        
        % Non-zeros in the column associated with this zero mode
        data = [component repmat(index, componentSize, 1) repmat(1.0, componentSize, 1)];
        nzList(currentRow+1:currentRow+componentSize,:) = data;
        currentRow      = currentRow+componentSize;
    end
    y = sparse(nzList(:,1), nzList(:,2), nzList(:,3), ...
        n, numComponents);
end
