classdef (Enumeration) GraphFormat < int8
    %GRAPHFORMAT Graph problem input format.
    %   This is an enumeration of supported graph problem input formats.
    %
    %   See also: GRAPH, GRAPHMETADATA.
    
    enumeration
        GENERATED(0)            % Graph instance programmaticaly generated -- not read from an input source
        MAT(1)                  % MATLAB mat file containing the metadata and graph adjacency matrix
        UF(2)                   % University of Florida Sparse Matrix Collection
        CHACO(3)                % Compressed row format
        DIMACS(4)               % DIMACS challenge format
        DOT(5)                  % dot graph plotting language
        PLAIN(6)                % GraphViz plain text format
        COMPRESSED_COLUMN(7)    % Compressed column format [i,j,aij]
    end
end
