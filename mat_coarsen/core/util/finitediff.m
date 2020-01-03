function J = finiteDiff(f,x,delta)
%FINITEDIFF Central finite differencing to approximate DF(X).
%   J = FINITEDIFF(F,X,DELTA) computes the Jacobian of F(X) at X using
%   central finite differencing at distance DELTA. If X is length-N, F(X)
%   is also assumed to be length-N; J is then an NxN matrix.

n = length(x);
J = zeros(n);
d = zeros(n,1);
for i = 1:n
    d(i) = delta;
    dfi = (f(x+d) - f(x-d))/(2*delta);
    J(i,:) = dfi';
end
