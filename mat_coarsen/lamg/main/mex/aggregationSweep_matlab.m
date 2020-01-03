function [x, x2, stat, aggregateSize, numAggregates] = ...
    aggregationSweep_matlab(bins, x, x2, stat, aggregateSize, numAggregates, N, D, W, ratioMax, maxCoarseningRatio)
%AGGREGATIONSWEEP Loop over bins of undecided nodes and aggregate nodes by
% updating the stat flag array and aggregateSize array. x and x2 (=x.^2)
% are also updated.
%
%   See also:COARSESETAFFINNITYENERGY.

numNodes = size(x,1);
for b = numel(bins):-1:1 % Scan connections in descending strength
    bin = bins{b};
    [x, x2, stat, aggregateSize, numAggregates] = ...
        processBin(bin, x, x2, stat, aggregateSize, numAggregates, N, D, W, ratioMax);
    
    % Stop if reached target coarsening ratio. Checking only after an
    % entire bin for easier future parallelization. Also less expensive.
    if (numAggregates <= numNodes*maxCoarseningRatio)
        break;
    end
end % for bin in bins
end

function [x, x2, stat, aggregateSize, numAggregates] = ...
    processBin(bin, x, x2, stat, aggregateSize, numAggregates, N, D, W, ratioMax)

cols = ones(1,size(x,2)); %#ok
K = size(x,2); %#ok

for index = 1:numel(bin)
    i = bin(index);

    %isTestIndex = (i == 4200);
    isTestIndex = ismember(i, [93      128227      139627      140707      141048      141083      141087]);
    %isTestIndex = 0;
    
    if (isTestIndex)
        fprintf('index: i=%d\n', i);
    end
    
    % Check that i was not changed by a previous node
    if (stat(i) >= 0)
        if (isTestIndex)
        fprintf('status(%d)=%d, skipping\n', i, stat(i));
        end
        continue;
    end
    
    % Find i's delta-affiliates that are undecided or seeds
    [Ci, dummy, Ni] = find(N(:,i)); %#ok
    clear dummy;
    smallAgg = stat(Ci) <= 0;        % Only undecided & seed neighbors
    Ci = Ci(smallAgg);
    if (isempty(Ci))
        if (isTestIndex)
            fprintf('Not aggregating i=%d, empty Ci\n', i);
        end
        continue;
    end
    Ni = Ni(smallAgg);
    
    %                     % Find the neighbor s the maximizes affinity s
    %                     = Ci(argmax(Ni)); xAggregate  = x(s,:);
    %                     x2Aggregate = xAggregate.^2;
    
    % Compute min_y Ei(x;y) - depends on i only
    [k, dummy, w]   = find(W(:,i)); %#ok
    clear dummy;
    w           = w';
    d           = D(i);
    d2          = 0.5*d;
    r           = w*x(k,:);
    q           = w*x2(k,:);
    y           = r/d;
    E           = (d2*y - r).*y + q;
    
    % Compute Ei(x;xj) - depends on both i and j
    rows    = ones(numel(Ci),1);
    r       = r(rows,:);
    q       = q(rows,:);
    E       = E(rows,:);
    xj      = x(Ci,:);
    
    % Set TV value at i to the TV value at the prospective seed j
    xJoint  = xj;
    
    % Aggregate value = weighted average of i and seed j
%     xi = x(i,:);
%     xi = xi(rows,:);
%     tj = aggregateSize(Ci)';
%     ti = aggregateSize(i);
%     ti = ti(rows,cols);
%     tj = tj(:,cols);
%     xJoint = (tj.*xj + ti.*xi)./(tj+ti);    
    
    Ec      = (d2*xJoint - r).*xJoint + q;
    
    % Find best seed s to aggregate i with: s = argmax_S [C_{is}], S = {s:
    % delta-nbhr of i with Ec/E <= mu}
    mu          = max(Ec./E, [], 2);       % Strict: all TVs must have good ratios
    %mu          = sqrt(sum((Ec./E).^2, 2)/K);  % L2 - more forgiving
    %smallRatio  = find((aggregateSize(Ci)+aggregateSize(i)<=2)' & mu <= ratioMax);
    smallRatio  = find(mu <= ratioMax);
    if (isTestIndex)
        %disp(E);
        %disp(Ec);
        %disp(Ec./E);
        %disp(mu);
    end
    %                disp('----------------------------------------------------');
    %                 i Ni Ci k w x(k,:) r q y E
    %                Ec mu smallRatio
    
    if (isempty(smallRatio))
        if (isTestIndex)
            [minMu, k]  = min(mu);
            s           = Ci(k(1));
            fprintf('Not aggregating i=%d with s=%d, mu=%.2f\n', i, s, minMu);
        end
        continue;
    else
        Ni          = Ni(smallRatio);
        Ci          = Ci(smallRatio);
        [dummy, k]      = max(Ni);         % Maximize affinity %#ok
        clear dummy;
        k           = k(1);
        s           = Ci(k);
        xAggregate  = xJoint(smallRatio(k),:);
        x2Aggregate = 0.5 * xAggregate.^2;
    end
    
    %------------------------
    % Aggregate i with s
    %------------------------
    if (isTestIndex)
        fprintf('Aggregating i=%d with s=%d, agg size=%d, mu=%.2f, C=%.2f\n', ...
            i, s, aggregateSize(s), mu(smallRatio(k)), Ni(k));
    end
    
    % Effect TV value on new aggregate
    x(i,:)  = xAggregate;
    x2(i,:) = x2Aggregate;
    
    % Update node status arrays
    stat(s) = 0;
    stat(i) = s;
    aggregateSize([i s])    = aggregateSize(s)+1;
    numAggregates           = numAggregates-1;
    %     if (isTestIndex)
    %         fprintf('i = %d, s = %d, numAggregates = %d\n', i, s, numAggregates);
    %     end
end % for index in bin
end