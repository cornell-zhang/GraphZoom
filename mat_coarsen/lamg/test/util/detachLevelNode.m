function level = detachLevelNode(level, s)
%detachLevelNode Remove a node from a coarse-level aggregate.
%   This method updates the coarse-level LEVEL upon detaching the
%   next-finer-level node S from its aggregate.

R = level.R;
% Size of aggregate containing s
aggregateSize = numel(find(R(find(R(:,s)),:))); %#ok

if (aggregateSize == 1)
    % s is already detached
    return;
else
    [i,j,r] = find(R);
    nz = [i j r];
    
    % Change s's aggregate entry to s (so that s is now its own aggregate)
    m       = size(R,1);
    m       = m+1; % New aggregate's index
    nz(s,1) = m;
    
    % Reconstruct level
    P = spconvert(nz)';
    
    % Initialize the next-coarser level - compute interpolation, Galerkin
    % coarsening and energy correction
    
    % TODO: fix to the correct options!!!
    mlOptions = amg.api.Options;
    mlOptions.energyCorrectionType      = 'flat';
    mlOptions.rhsCorrectionFactor       = 4/3;
    
    level = amg.level.Level(level.index, ...
        level.state, ...
        level.relaxFactory, ...
        'name', level.g.metadata.name, ...
        'fineLevel', level.fineLevel, 'P', P, ...
        'options', mlOptions);
    
end


end
