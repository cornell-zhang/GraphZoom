function f = ball_list(c,r)
%BALL_LIST Create an index list for a d-dimensional ball.
%   F = BALL_LIST(C,R) creates a kxd array F from a d-dimensional
%   coordinates C and a vector R. F contains the d-dimensional indices lying
%   in the ball of radius R around C (if R is not a constant vector, this is an ellipse).
%   
%   See also BOX_LIST, NDGRID.

% Author: Oren Livne
%         06/18/2004    Version 1: Created

dim         = length(c);
f           = box_list(c - r,c + r);        % Full box around center
inner       = find(sum(((f-repmat(c,size(f,1),1)).^2)./repmat(r.^2,size(f,1),1),2) <= 1);        % Find indices that lie in the bal;
f           = f(inner,:);                                               % Make f the ball
