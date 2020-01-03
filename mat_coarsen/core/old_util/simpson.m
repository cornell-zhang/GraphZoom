function y = simpson(f,a,b,n)
%SIMPSON Simpson's rule integration with equally spaced points
%
%  y=SIMPSON(f,a,b,n) returns the Simpson's rule approximation to
%  the integral of f(x) over the interval [a,b] using n+1 equally
%  spaced points.  The input variable f is a string containing the
%  name of a function of one variable.  The function f(x) must accept
%  a vector argument and return the vector of values of the function.
%
%  NOTE: n must be even.

h=(b-a)/n;
x=linspace(a,b,n+1);
fx=feval(f,x);

y=h/3*(fx(1)+4*sum(fx(2:2:n))+2*sum(fx(3:2:n-1))+fx(n+1));

