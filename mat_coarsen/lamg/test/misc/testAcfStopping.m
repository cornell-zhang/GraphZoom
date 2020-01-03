function testAcfStopping(e1, e2, c)
%TESTACFSTOPPING Test stopping criterion for ACF estimation.
%   TESTACFSTOPPING(E1,E2,C) simulates an iterative process with two
%   eigenmodes whose convergence per cycle is 1-E1 and 1-E2, respectively.
%   The values of E1,E2 should typically be << 1. The question is when to
%   stop, and we show by illustration that a good ACF estimate R(N) is
%   obtained when the relative change in the reduction factor R=R(N) at
%   iteration N (i.e. (R(N)-R(N-1))/R(N-1)) is less than C*(1-R) for some
%   small C. The default value is C=0.1.

if (nargin < 1)
    e1 = 0.01;
end
if (nargin < 2)
    e2 = 4*e1;
end
if (nargin < 3)
    c = 0.01;
end
d = e2-e1;
% Initial value, then adjusted according to stop
N = min(1e+5, max(20, floor(0.02*log(1/c)/(d*e1))));

stop = stoppingCriterion(N, e1, e2, c);
N = min(1e+5, max(20, floor(2.3*stop)));
[stop, n, r, rChange, acfEstimate] = stoppingCriterion(N, e1, e2, c);

generatePlots(e1, e2, c, n, r, rChange, stop, acfEstimate);

end

%------------------------------------------------------------------
function [stop, n, r, rChange, acfEstimate] = stoppingCriterion(N, e1, e2, c)
% Estimate the ACF - experiment with N iterations.

r1 = 1-e1;
r2 = 1-e2;
n = (1:N)';
a = r1.^n + r2.^n;
% Reduction factor
r = exp(diff(log([2; a])));

rChange = exp(diff(log(r)))-1;
rChange = [rChange(1); rChange];

% Stopping criterion
ratio = rChange ./ (1-r);
k = 10;
averageRatio = filter(ones(1, k)/k, [1 zeros(1, k-1)], ratio);
averageRatio(1:k) = averageRatio(k+1); % Initial conditions
stop = min(find(averageRatio < c, 1));
acfEstimate = r(stop);

%[rChange./(1-r) (r1-r)./r1]
%stop
end

%------------------------------------------------------------------
function generatePlots(e1, e2, c, n, r, rChange, stop, acfEstimate)
% Generate figure with plots.

r1 = 1-e1;
N = n(end);

figure(1);
clf;
h = gcf;
set(h, 'Position', [150 50 900 600]);

subplot(1,2,1);
plot(n, r);
hold on;
yLimit = [min(r)-0.001 max(r)+0.001];
xlim([1 N]);
ylim(yLimit);
line([stop stop], yLimit, 'color', 'red');
xlabel('Iteration number (n)');
ylabel('Reduction per iteration (R)');
title(sprintf('Amplitude Reduction, \\epsilon_1=%.3f \\epsilon_2=%.3f, C=%.2e\nTrue ACF = %.5f, estimate = %.5f, accuracy = %.2e', ...
    e1, e2, c, r1, acfEstimate, abs(acfEstimate-r1)/r1));
shg;

subplot(1,2,2);
plot(n, rChange./(1-r), 'b', n, (r1-r)./r1, 'g');
xlim([1 N]);
yLimit = ylim;
line([stop stop], yLimit, 'color', 'red');
xlabel('Iteration number (n)');
ylabel('Relative changes');
legend('\alpha_n/(1-R_n)', '|r_1-R_n|/r_1');
title('Relative Change in Reduction');
shg;
end
