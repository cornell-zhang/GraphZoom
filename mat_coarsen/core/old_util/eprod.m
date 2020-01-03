function y = eprod(x,t)
%EPROD  evaluate the interpolation error product
%
%      EPROD([x0 x1 ... xn],t] returns the product
%      (t-x0)(t-x1)...(t-xn), i.e., the monic polynomial
%      of degree n with the give roots.  t may be a vector,
%      in which case a vector of the same length is returned.

% The formula y=polyval(poly(x),t) works, but is much more subject
% to round-off error for badly scaled data.

shape = size(t);
t=t(:);
x=x(:);
y = prod(ones(size(x))*t'-x*ones(size(t')));
y=reshape(y,shape);
