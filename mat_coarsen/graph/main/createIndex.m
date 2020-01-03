function r = createIndex(dir, outputFile)
%CREATEINDEX Print graph statistics.
%   R=CREATEINDEX(DIR, OUTPUTFILE) creates an index R of the data directory
%   DIR relative to GLOBAL_VARS.DATA_DIR dir and saves it in OUTPUTFILE.
%
%   R=CREATEINDEX(DIR) uses OUTPUTFILE=[GLOBAL_VARS.data_dir '/' dir
%   '_index.mat'].
%
%   See also: PRINTER, READER.

config;
global GLOBAL_VARS;
if (nargin < 2)
    outputFile = [GLOBAL_VARS.data_dir '/' dir '_index.mat'];
    % Don't override the index file until we're done graphStats'in
    %     f = fopen(outputFile, 'w'); if (f < 0)
    %         error('Cannot open file ''%s'' for writing', outputFile);
    %     else
    %         fclose(f);
    %     end
end

[dummy, r] = graphStats(dir); %#ok
clear dummy;
save(outputFile, 'r');

end