function y = trapez(f,a,b,n)
%TRAPEZ Trapezoidal rule integration with equally spaced points
%
%  y=TRAPEZ(f,a,b,n) returns the trapezoidal rule approximation to
%  the integral of f(x) over the interval [a,b] using n+1 equally
%  spaced points.  The input variable f is a string containing the
%  name of a function of one variable.  The function f(x) must accept
%  a vector argument and return the vector of values of the function.

h=(b-a)/n;
x=linspace(a,b,n+1);
fx=feval(f,x);

y=h/2*(fx(1)+2*sum(fx(2:n))+fx(n+1));

