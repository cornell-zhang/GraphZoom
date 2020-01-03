function h=mygplot(A,xy,lc)
%GPLOT Plot graph, as in "graph theory".
%   GPLOT(A,xy) plots the graph specified by A and xy. A graph, G, is a set
%   of nodes numbered from 1 to n, and a set of connections, or edges,
%   between them.
%
%   In order to plot G, two matrices are needed. The adjacency matrix, A,
%   has a(i,j) nonzero if and only if node i is connected to node j.  The
%   coordinates array, xy, is an n-by-2 matrix with the position for node i
%   in the i-th row, xy(i,:) = [x(i) y(i)].
%
%   GPLOT(A,xy,LineSpec) uses line type and color specified in the string
%   LineSpec. See PLOT for possibilities.
%
%   H = GPLOT(A,xy) returns the plot handle H, which can be used fo further
%   customize the plot.
%
%   See also GPLOT, SPY, TREEPLOT.

[i,j] = find(A);
[dummy, p] = sort(max(i,j)); %#ok
clear dummy;
i = i(p);
j = j(p);

X = [ xy(i,1) xy(j,1)]';
Y = [ xy(i,2) xy(j,2)]';

if isfloat(xy) || nargout ~= 0
    X = [X; NaN(size(i))'];
    Y = [Y; NaN(size(i))'];
end

if nargin < 3
    lc = '';
end
if ~isfloat(xy)
    [lsty, csty, msty] = gplotGetRightLineStyle(gca,lc);
    plot(X,Y,'LineStyle',lsty,'Color',csty,'Marker',msty);
else
    h = plot(X(:),Y(:),lc);
end

%-----------------------------------------------------------------------
function [lsty, csty, msty] = gplotGetRightLineStyle(ax, lc)
%  gplotGetRightLineStyle
%    Helper function which correctly sets the color, line style, and marker
%    style when plotting the data above.  This style makes sure that the
%    plot is as conformant as possible to gplot from previous versions of
%    MATLAB, even when the coordinates array is not a floating point type.
co = get(ax,'ColorOrder');
lo = get(ax,'LineStyleOrder');
holdstyle = getappdata(gca,'PlotHoldStyle');
if isempty(holdstyle)
    holdstyle = 0;
end
lind = getappdata(gca,'PlotLineStyleIndex');
if isempty(lind) || holdstyle ~= 1
    lind = 1;
end
cind = getappdata(gca,'PlotColorIndex');
if isempty(cind) || holdstyle ~= 1
    cind = 1;
end
nlsty = lo(lind);
ncsty = co(cind,:);
nmsty = 'none';
%  Get the linespec requested by the user.
[lsty,csty,msty] = colstyle(lc);
if isempty(lsty)
    lsty = nlsty;
end
if isempty(csty)
    csty = ncsty;
end
if isempty(msty)
    msty = nmsty;
end

