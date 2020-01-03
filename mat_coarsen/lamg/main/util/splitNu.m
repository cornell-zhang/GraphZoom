function [nuPre, nuPost] = splitNu(nu, nuDesign)
%SPLIT_NU Split and return #relaxations n at the next-finer level of a
%   coarse level.
%   Call as [NUPRE,NUPOST] = SPLITNU(NU,NUDESIGN).

switch (nuDesign)
    case 'pre'
        nuPre  = nu;
        nuPost = 0;
    case 'post'
        nuPre  = 0;
        nuPost = nu;
    case 'split_evenly'
        nuPre  = ceil(nu/2);
        nuPost = nu - nuPre;
    case 'split_evenly_post'
        nuPost = ceil(nu/2);
        nuPre  = nu - nuPost;
    otherwise
        error('MATLAB:splitNu:InputArg', 'Unknown nu design strategy ''%s''', ...
            nuDesign);
end
end
