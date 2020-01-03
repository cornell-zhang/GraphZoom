function x = chebpts(a,b,n)
%CHEBPTS Compute the Chebyshev points
%
%      CHEBPTS(a,b,n) returns a vector of length n containing
%      the n Chebyshev points on the interval [a,b].

x=(b+a-(b-a)*cos((2*(0:n-1)+1)*pi/(2*n)))/2;

