function s = sizeString(dummy1, data, dummy2) %#ok
%SIZESTRING A string indicating a graph's size.
%   S = SIZESTRING(METADATA, DATA, DETAILS) returns 'big' or 'small'
%   depending on the graph's edge count. Useful for Printer functor tests.
%
%   See also: PRINTER.

if (data(1) < 100)
    s = 'small';
else
    s = 'big';
end

end
