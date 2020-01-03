function [cc, dd, L, D, setup] = testDiffusionVsAffinity(n, nu, K, outputDir)
%TESTDIFFUSIONVSAFFINITY Compare the diffusion distance with affinity.
%   testDiffusionVsAffinity(n, nu, K, outputDir) compares the diffusion
%   distance with affinity for a Gaussian kernel Laplacian of a cloud of n
%   points consisting of two clusters. nu is the number of TV sweeps /
%   diffusion time and K is the number of test vectors
%
%   See also: AFFINITYMATRIX, SETUP, EIGS.

if (nargin < 1)
    n   = 300;          % # points
end
if (nargin < 2)
    nu  = 3;            % # relax sweeps / random walk time
end
if (nargin < 3)
    K   = 8;            % # test vectors
end
if (nargin < 4)
    outputDir = [];
end
savePlots = (nargin >= 4) && ~isempty(outputDir);
config;

c1  = [1 -1];       % Center point of cluster #1
c2  = [1  1];       % Center point of cluster #2
e   = 1.0;          % Gaussian width

% Generate a point cloud around c1 and c2
s = [repmat(c1, n/2, 1); repmat(c2, n/2, 1)];
r = rand(n,1);
t = 2*pi*rand(n,1);
s = s + [1.2*r.*cos(t) r.*sin(t)];

% Generate Gaussian kernel
[x1,y1]=ndgrid(s(:,1),s(:,1));
[x2,y2]=ndgrid(s(:,2),s(:,2));
L = exp(-((x1-y1).^2 + (x2-y2).^2)/e);

% Compute diffusion distance dd between all node pairs
d = sum(L,2);
D = diag(d);
D2 = diag(d.^(-0.5));
M = D2*L*D2;
[v,lam]=eig(M);
[lam,i]=sort(diag(lam),'descend'); v = v(:,i);
Psi = v*diag(lam.^nu);
[i,j]=ndgrid(1:n,1:n);
dd = reshape(sum((Psi(i,:)-Psi(j,:)).^2,2),n,n);

% Compute affinities dd between all node pairs
lamg = Solvers.newSolver('lamg', 'tvNum', K, 'tvSweeps', nu, 'maxDirectSolverSize', n-1, 'setupNumLevels', 2);
setup = lamg.setup('adjacency', sparse(L - diag(diag(L))));
A = setup.level{1}.A;
x = setup.level{1}.x;
cc = full(1 - affinitymatrix(A, x));

r = corrcoef(cc(:),dd(:));
fprintf('Correlation(1-C,D) = %f\n', r(1,2));

% c invariant to diagonal scaling of x, so cc2=cc!
% cc2 = full(1 - affinitymatrix(A, diag(d.^0.5)*x));
% r = corrcoef(cc2(:),dd(:));
% fprintf('Correlation(1-C,D) = %f\n', r(1,2));

% Plots
%figure(1);
%clf;
%h = zeros(4,1);
files = cell(4,1);

%subplot(2,2,1);
figure(1);
clf;
h = scatter(s(:,1), s(:,2), 40, cc(:,n/2+1), 'o', 'filled');
xlabel('s');
ylabel('t');
files{1} = 'point_cloud';
% title('Point cloud');
axis equal;
if (savePlots)
    saveCurrentFigure(outputDir, files{1});
end
%offset = 0.3; xlim([min(s(:,1))-offset max(s(:,1))+offset]);
%ylim([min(s(:,2))-offset max(s(:,2))+offset]);

%subplot(2,2,2);
figure(2);
clf;
sample = 1:9:numel(cc);
scatter(cc(sample), dd(sample), 'k');
files{2} = 'one_minus_c_vs_d';
%title('Affinity vs. Diffusion Distance');
xlabel('1-c');
ylabel('f');
if (savePlots)
    saveCurrentFigure(outputDir, files{2});
end

%subplot(2,2,3);
figure(3);
clf;
imagesc(uint32(255*(1-dd/max(dd(:)))));
%title('Diffusion Distance');
files{3} = 'diffusion_distance';
if (savePlots)
    saveCurrentFigure(outputDir, files{3});
end

%subplot(2,2,4);
figure(4);
clf;
imagesc(uint32(255*(1-cc/max(cc(:)))));
%title('Affinity (1-c)');
files{4} = 'one_minus_c';
if (savePlots)
    saveCurrentFigure(outputDir, files{4});
end

%set(gcf, 'Position', [48 114 735 553]);
%shg;

% if (savePlots)
%     % Copy subplots to placeholder figure to save them to files
%     for i = 1:numel(h)
%         figure(2);
%         clf;
%         axes;
%         copyobj(h(i), gca);
%         saveCurrentFigure(outputDir, files{i});
%     end
%     close(2);
% end

end

%----------------------------------------------------------------------
function saveCurrentFigure(outputDir, figureTitle)
% Save figure in output directory
save_figure('epsc',  '%s/%s.eps', outputDir, figureTitle);
save_figure('png' , '%s/%s.png', outputDir, figureTitle);
end