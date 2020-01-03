function s = formatAcf(x, precision)
%FORMATACF Formatted printout of an ACF value.
%   S = FORMATACF(X,PRECISION) prints a string for displaying X if X is not
%   too close to 1, or 1-X, if X is close enough to 1. The default is
%   PRECISION=3.
%
%   See also: SPRINTF.

if (nargin < 2)
    precision = 3;
end

d = x-1;
if (abs(d) > 2*10^(-precision))
    formatString = sprintf('%%.%df', precision);
    s = sprintf(formatString, x);
elseif (abs(d) > 2*10^(-(precision+2)))
    formatString = sprintf('%%.%df', precision+2);
    s = sprintf(formatString, x);
else
    s = sprintf('1%+.1e', d);
    % On a Windows system, convert PC-style exponential notation (three
    % digits in the exponent) to UNIX style notation (two digits)
    if (ispc)
        if (abs(d) <= 2e-9)
            s = strrep(s, 'e-00', 'e-0');
            s = strrep(s, 'e-01', 'e-1');
        else
            s = strrep(s, 'e-00', 'e-0');
        end
    end
end

end

