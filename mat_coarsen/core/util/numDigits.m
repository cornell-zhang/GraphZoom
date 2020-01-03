function numDigits = numDigits(x)
%NUMDIGITS Number of digits of a decimal non-negative integer.
%   NUMDIGITS(X) returns the number of digits in the decimal representation
%   of a non-negative integer X. If X is an array, NUMDIGITS(X) is applied
%   element-wise.
%
%   See also: LOG10.

if (~isNonnegativeIntegral(x))
    error('MATLAB:numDigits:InputArg', 'Accepts an non-negative integer argument only');
else
    numDigits           = ceil(log10(x+1e-5));
    numDigits(x == 0)   = 1;
end

end

