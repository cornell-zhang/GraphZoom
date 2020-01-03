function s = elapsedTime(dummy1, dummy2, details)
%ELAPSEDTIME A formatted string of the elapsed time of a run.
%   S = ELAPSEDTIME(METADATA, DATA, DETAILS) returns a formatted string
%   based on DETAILS.time.
%
%   See also: PRINTER, BATCHRESULT.

s = sprintf('%.6f seconds', details.time);
