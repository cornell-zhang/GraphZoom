classdef (Hidden, Sealed) WriterMat < graph.writer.Writer
    %WRITERMAT Writes a graph problem into a MATLAB MAT file.
    %   This interface writes a GRAPH adjacency matrix and metadata to a
    %   MAT file.
    %
    %   See also: WRITER, GRAPH.
    
    %======================== IMPL: Writer ============================
    methods
        function write(obj, g, file) %#ok<MANU>
            % Write a graph instance to MAT file.
            
            % Write graph in MAT format
            metadata            = g.metadata;
            metadata.formatType = graph.api.GraphFormat.MAT; % Override original format
            metadata.file       = file; % Override output file name
            A                   = g.adjacency;
            
            if (~isempty(g.coord))
                coord = g.coord;  %#ok
            end
            
            outputDir = fileparts(file);
            if (~exist(outputDir, 'dir'))
                mkdir(outputDir);
            end
            
            if (~isempty(g.coord))
                save(file, 'metadata', 'A', 'coord');
            else
                save(file, 'metadata', 'A');
            end
        end
    end
    
end
