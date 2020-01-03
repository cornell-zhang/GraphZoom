function y = lacunary(x,nu)
%LACUNARY Summary of this function goes here
%   Y=LACUNARY(X,NU) returns an approximation to the infinite generalized
%   Lacunary series Y = X + X.^NU + X.^(NU^2) + ... . The function
%   converges for NU > 0 if and only if ABS(X) < 1. X may be a vector; NU
%   may only be scalar.
%
%   See also: http://en.wikipedia.org/wiki/Lacunary_function

error(nargchk(1, 2, nargin, 'struct'));
if (nu < 0)
    error('LACUNARY:InputArg', 'The power nu must be positive');
end
transpose = (size(x,2) > 1);
if (transpose)
    x = x';
end
sz = numel(x);

% Let n = last term in the partial sum used to approximate the function.
% Error ~ next term ~ x^(nu^(n+1)) ==> n+1 >= log(log(e)/log(x))/log(nu).
e = 1e-16;
n = floor(log(log(e)./log(x))/log(nu));

% Match the dimensions of x,nu, n and compute sum(x^(nu^n)).
[NU,N] = ndgrid(repmat(nu, sz, 1), 0:1:n);
y = sum(repmat(x, 1, size(N, 2)).^(NU.^N), 2);
if (transpose)
    y = y';
end

end
