function L = randomLaplacian(lam)
%RANDOMLAPLACIAN Random Laplacian with a given spectrum.
%   L = randomLaplacian(lam) generates a random Laplacian matrix with
%   spectrum [0; lam].
%
%   See also: SPRANDSYM.

if (size(lam,2) > 1)
    lam = lam';
end
n       = numel(lam)+1;
[Q, dummy]  = schur(full(sprandsym(n, 0.5))); %#ok
%e       = ones(n,1); %#ok
Q       = [r; Q];
T       = [[1/sqrt(n) -mean(Q)];[ones(n-1,1)/sqrt(n) Q]];
L       = T'*diag([0; lam])*T;

end

