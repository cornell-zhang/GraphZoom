function plotAcfResults(result, fig)
%PLOTACFRESULTS Generate multilevel cycle asymptotic vector and residual plots.
%   Suitable for grid tests. PLOTACFRESULTS(RESULT, FIG) starts generating
%   plots at figure number FIG.

if (nargin < 2)
    fig = 0;
end

% Debugging plots
level   = result.details{1}.setup.level{1};
n       = level.g.metadata.attributes.n;
%eb      = result.details{1}.setup.level{2}.energyBuilder;

coord   = level.g.coord;
t       = reshape(coord(:,1), n);
s       = reshape(coord(:,2), n);
[tt,ss]    = ndgrid('fd', 1:n(1), 1:n(2));

%            T = [t(:) s(:)];
%
%             edge    = level.g.edge; %edgeCoord =
%             0.5*(level.g.coord(edge(:,1),:) +
%             level.g.coord(edge(:,2),:)); edgeCoord = 0.5*(T(edge(:,1),:)
%             + T(edge(:,2),:)); tri     = delaunay(edgeCoord(:,1),
%             edgeCoord(:,2));
x = result.details{1}.asymptoticVector;
A = level.A;
r = A*x;

% Asymptotic cycle vector
figure(fig+1);
clf;
surf(t, s, reshape(x,n));
title('Asymptotic Cycle Error');
xlabel('t');
ylabel('s');
%             %plot(x);

% Asymptotic cycle residual
figure(fig+2);
clf;
%surf(t, s, reshape(abs(r),[n n]));
surf(t, s, reshape(r,n));
view(2); colorbar;
title('Asymptotic Cycle Residual');
xlabel('t1');
ylabel('t2');

figure(fig+3);
clf;
surf(tt, ss, reshape(abs(r),n));
view(2); colorbar;
title('Asymptotic Cycle Residual');
xlabel('i1');
ylabel('i2');

%             % Goodness-of-fit to TVs figure(3);
%             surf(reshape(eb.fit,n*ones(1,dim)./mlOptions.coar
%             seningRatio)); view(2); colorbar; title('Fit Value');
%             xlabel('t'); ylabel('s');

%             % Fit statsistics figure(101); trisurf(tri, edgeCoord(:,1),
%             edgeCoord(:,2), eb.numInterpTerms); view(2); colorbar;
%             title('#Coarse terms interpolated to a fine term');
%             xlabel('t'); ylabel('s');
%
%             figure(102); trisurf(tri, edgeCoord(:,1), edgeCoord(:,2),
%             eb.fit); view(2); colorbar; title('Energy Interpolation
%             Fit'); xlabel('t'); ylabel('s');
%
%             % Display the worst fits
%             xx=g.metadata.attributes.subscript{1}(edge);
%             yy=g.metadata.attributes.subscript{2}(edge); fitData =
%             [xx(:,1) yy(:,1) xx(:,2) yy(:,2) eb.fit]; badFit  =
%             fitData(fitData(:,5) > 2*median(eb.fit),:);
%             disp(sortrows(badFit,[1 2]));
%
%             % TV plot figure(201); x = level.x(:,1); surf(t, s,
%             reshape(x,[n n])); title('TV #1'); xlabel('t'); ylabel('s');
% %             %plot(x);
end
