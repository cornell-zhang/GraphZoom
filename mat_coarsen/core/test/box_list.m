function f = box_list(start,finish)
%BOX_LIST Create an index list for a d-dimensional box.
%   F = BOX_LIST(START,FINISH) creates a kxd array F from two d-dimensional
%   coordinates START and FINISH. F contains all the d-dimensional indices
%   in the box [START(1),FINISH(1)]x...x[START(d),FINISH(d)].
%   
%   See also NDGRID.

% Author: Oren Livne
%         06/17/2004    Version 1: Created

dim         = length(start);
if (dim == 1)
    f = [start:finish]';
else
    a           = cell(1,dim);
    for d = 1:dim,
        a{d} = [start(d):finish(d)];
    end
    b           = cell(1,dim);
    [b{:}]      = ndgrid(a{:});
    for d = 1:dim,
        b{d}    = b{d}(:);
    end
    f           = cat(2,b{:});        
    f           = sortrows(f,[dim:-1:1]);
end
