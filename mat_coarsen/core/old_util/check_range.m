function b = check_range(a,start,finish)
%CHECK_RANGE Check range of a d-dimensional index list.
%   Given A, a nxd list of d-dimensional indices, we return a nx1 boolean
%   array B = CHECK_RANGE(A,START,FINISH) that indicates whether A(i,:) is
%   in the d-dimensional cube [START(1),FINISH(1)] x ... [START(d),FINISH(d)].
%
%   See also FIND, REPMAT.
 
% Author: Oren Livne
% Date  : 06/17/2004    Version 1: created.

if (isempty(a))
    b = [];
    return;
end

b = min((repmat(start,[size(a,1),1]) <= a) & ...
    (a <= repmat(finish,[size(a,1),1])),[],2);
