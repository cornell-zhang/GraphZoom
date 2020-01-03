function s = printData(data, title, format)
%Print a 1-D array with a title. Useful for debugging printouts.

if (nargin < 3)
    format = '%+.3f ';
end

s = [ ...
    sprintf('%s = ', title) ...
    sprintf(format, data) ...
    ];
end
