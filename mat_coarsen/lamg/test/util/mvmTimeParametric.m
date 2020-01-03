function [tRandom, tBanded, n] = mvmTimeParametric(m, d, numExperiments)
%mvmTimeParametric Sparse Matrix-vector multiplication timing test.
%   [TRANDOM, TBANDED, N] = mvmTimeParametric(M, D, NUMEXPERIMENTS)
%   computes the time TRANDOM to compute A*x where A = nxn symmetric sparse
%   matrix with roughly M non-zeros and average non-zeros per row D, vs.
%   the time TBANDED for banded matrices with the D non-zeros per row. The
%   matrix dimensions n and the times t are returned in the output arrays,
%   one for each value of M.
%
%   See also: MVMTIME, TESTERLAXTIME.

if (nargin < 3)
    numExperiments = 100;
end

numM = numel(m);
numD = numel(d);
tRandom = zeros(numM,numD);
tBanded = zeros(numM,numD);
n       = zeros(numM,numD);
for k = 1:numD
    avgDegree = d(k);
    fprintf('avg degree = %d\n', avgDegree);
    % Calculate diagonal ranges for banded matrix tests
    if (mod(avgDegree,2) == 0)
        low = -avgDegree/2;
        high = avgDegree/2 - 1;
    else
        low = -(avgDegree-1)/2;
        high = (avgDegree-1)/2;
    end
    for i = 1:numM
        N           = round(m(i)/avgDegree);
        density     = avgDegree/N;
        totalTimeRandom = 0;
        totalTimeBanded = 0;
        for j = 1:numExperiments
            x = rand(N,1);
            A = sprandsym(N, density);
            ts = tic;
            A*x; %#ok
            totalTimeRandom = totalTimeRandom + toc(ts);
            
            B = spdiags(rand(N,avgDegree), low:high, N, N);
            ts = tic;
            B*x; %#ok
            totalTimeBanded = totalTimeBanded + toc(ts);
        end
        n(i,k)       = N;
        tRandom(i,k) = totalTimeRandom/numExperiments;
        tBanded(i,k) = totalTimeBanded/numExperiments;
        fprintf('n=%.1e  m=%.1e  rand=%.2e (nnz=%.1e) banded=%.2e (nnz=%.1e)\n', ...
            n(i,k), m(i), tRandom(i,k), nnz(A), tBanded(i,k), nnz(B));
    end
end

end