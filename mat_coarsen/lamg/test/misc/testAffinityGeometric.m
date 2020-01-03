% Test affinities with geometric TVs in the 1-D grid Laplacian.

K = 5;              % # TVs
h = 0.01;           % Meshsize
theta = 2*pi*h;     % Scaled base frequency

R = (1:10)';
C       = zeros(size(R));
Cpoly   = zeros(size(R));
k       = 1:K;
x       = ones(size(k));
for i = 1:length(R)
    r = R(i);
    y = exp(1i*theta*r*k);
    C(i) = affinity_l2(x,y);
    y = 1 + (r*h).^k;
    Cpoly(i) = affinity_l2(x,y);
    fprintf('r = %.2f  c = %.2e  cpoly = %.2e\n', r, C(i), Cpoly(i));
end
plot(R,C, 'bo-', R,Cpoly,'ro-');
