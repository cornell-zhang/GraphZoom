classdef Writer < handle
    %WRITER Write a graph problem to file.
    %   This interface writes a GRAPH instance to an output file.
    %
    %   See also: GRAPH, WRITERFACTORY.
    
    %======================== METHODS =================================
    methods (Abstract)
        write(obj, g, file, varargin)
        % Write the graph instance g to file. varargin contains writing
        % options.
    end
    
end
