function [t, s] = mvmTime(A, n)
%mvmTime Sparse Matrix-vector multiplication timing test.
%   [T,S]=mvmTime(A,N) computes the time required to evaluate A*x where A =
%   sparse matrix. N random experiments are performed. T=mvmTime(A)
%   performs 10 experiments. If two output arguments are requested, S holds
%   the standard deviation from the mean time T.
%
%   See also: TESTERLAXTIME.

if (nargin < 2)
    n = 10;
end

t  = 0;
s  = 0;
sz = size(A,1);
for i = 1:n
    x = rand(sz,1);
    ts = tic;
    A*x; %#ok
    thisTime = toc(ts);
    t = t + thisTime;
    s = s + thisTime^2;
end
t = t/n;
s = sqrt(s/n - t^2);

end