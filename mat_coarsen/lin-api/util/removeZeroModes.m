function x = removeZeroModes(x, componentIndex)
%REMOVEZEROMODES Orthogonalize x to Laplacian zero modes.
%   componentIndex contains a graph's components.In particular, if
%   componentIndex is, this method is equivalent to x = x - mean(x).

numComponents = numel(componentIndex);
if (isempty(componentIndex) || numComponents == 1)
    % Single-component case: optimized implementation
    if (size(x,1) == 1)
        x = x - mean(x);
    else
        rows    = ones(size(x,1),1);
        xc      = mean(x);
        x       = x - xc(rows,:);
    end
else
    for i = 1:numComponents
        component       = componentIndex{i};
        xc              = x(component,:);
        xcMean          = mean(xc);
        rows            = ones(size(xc,1),1);
        x(component,:)  = xc - xcMean(rows,:);
    end
    % General problem
    %                 for i = 1:size(y,2)
    %                     z = y(:,i); x = x - (z'*x)*z;
    %                 end
end
end
