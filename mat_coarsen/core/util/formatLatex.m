function s = formatLatex(x, precision)
%FORMATACF Formatted latex printout of a floating point number
%   S = FORMATLATEX(X) prints a floating point number in latex for with
%   precision P of a "%e" format. The default is
%   PRECISION=3.
%
%   See also: SPRINTF.

if (nargin < 2)
    precision = 3;
end

formatString = sprintf('%%.%de', precision);
s = sprintf(formatString, x);

if ((x >= 1) && (x < 10))
    s = regexprep(s, '(.*)e\+000', '$1 \\times 10^{0}');
else
    s = regexprep(s, '(.*)e(-?)(\+?)0*(0?\d*)', '$1 \\times 10^{$2$4}');
end

end

