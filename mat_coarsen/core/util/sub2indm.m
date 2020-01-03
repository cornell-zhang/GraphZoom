function f = sub2indm(siz,a)
%SUB2INDM Linear index from multiple subscripts in matrix form.
%   SUB2INDM is used to determine the equivalent single index corresponding
%   to a given set of subscript values.
%
%   IND = SUB2INDM(SIZ,A) returns the linear index equivalent to the N
%   subscripts in the arrays A(:,1),...,A(:,N) for an array of size SIZ.
%
%   See also IND2SUB, IND2SUBM, SUB2IND.

% Author: Oren Livne Date  : 06/23/2004    Added comments.

dim                 = length(siz);
% outside             = find(~check_range(a,ones(size(siz)),siz));    %
% These indices are outside the domain if (~isempty(outside))
%     a(outside,:)    = ones(length(outside),dim);                    % Set
%     dummy values @ outside inds, so that sub2ind will work
% end

if (dim == 1)
    f = a;
else
    temp                = cell(dim,1);
    for d = 1:dim,
        temp{d}         = a(:,d);
    end
    
    f                   = sub2ind(siz,temp{:});                         % dD -> 1D indices
    %f(outside)          = -1;                                           %
    %Outside indices => ind = -1
end
