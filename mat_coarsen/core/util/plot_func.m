function plot_func(func,fignum,t)
%PLOT_FUNC Surf-plot a 2D function, defined on a level (grid).
%   PLOT_FUNC(FUNC,FIGNUM,T) surf-plots the 2D matrix FUNC (vs. gridpoint
%   indices in x and y) in figure no. FIGNUM, titled to the string T.
%
%    Input:
%    func   = data matrix
%    fignum = number of figure to be generated.
%    tt     = title string.
%    Output:
%    None (displayed figure).
%
%    See also SURF.

% Revision history:
% 05/30/2004    Oren Livne    Added to toolkit.

if (nargin < 2)
    fignum = 1;
end
if (nargin < 3)
    tt = '2D Function';
end

a = fignum;
figure(a);
clf;
surf(func');
xlabel('x');
ylabel('y');
title(t);
