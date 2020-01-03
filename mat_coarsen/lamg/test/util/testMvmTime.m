%testMvmTime Sparse Matrix-vector multiplication timing test.
%   This script generates plots of MVM times for random vs. banded matrices
%   of increasing dimension and varying average non-zero per row.
%
%   Banded matrix times should be smaller than random matrix times because
%   MATLAB's MVM routine can take advantage of memory locality.
%
%   See also: MVMTIMEPARAMETRIC, MVMTIME.

% Generate times t (random matrices) and s (banded matrices)
nnz = 2.^(14:21)';
degree = [3 6 12 120];
[t, s, n] = mvmTimeParametric(nnz, degree, 10);

% Plot random matrix results. Plot should increase with nnz.
figure(1);
clf;
semilogx(nnz, t./repmat(nnz, 1, numel(degree)), 'o-');
legend('d=3', 'd=6', 'd=12', 'd=120', 'Location', 'Northwest');
title('Random Matrices');
xlabel('#non-zeros');
ylabel('MVM time / edge [sec]');
shg;

% Plot banded matrix results. Plots should be flat.
figure(2);
clf;
semilogx(nnz, s./repmat(nnz, 1, numel(degree)), 'o-');
legend('d=3', 'd=6', 'd=12', 'd=120', 'Location', 'Northwest');
title('Banded Matrices');
xlabel('#non-zeros');
ylabel('MVM time / edge [sec]');
shg;

% figure(3); clf; loglog(m, t1, 'ro-', m, t2, 'bo-', m, t3, 'ko-', m, t4,
% 'go-'); legend('d=3', 'd=6', 'd=12', 'd=120', 'Location', 'Northwest');
% xlabel('#edges'); ylabel('MVM time [sec]'); shg;
