classdef (Hidden, Sealed) WriterDot < graph.writer.Writer
    %WRITERDOT Writes a graph problem into a dot file.
    %   This interface writes a GRAPH adjacency matrix to a file in dot
    %   format (a language for plotting graphs).
    %
    %   See also: WRITER, GRAPH.
    
    
    %=========================== PROPERTIES ==============================
    properties (Constant, GetAccess = private)
        logger = core.logging.Logger.getInstance('graph.writer.WriterDot')
    end
    
    %======================== IMPL: Writer ============================
    methods
        function write(obj, g, file, varargin)
            % Write a graph instance to a dot file.
            
            % TODO: replace by an inputParser
            options = graph.writer.WriterDot.parseWriteArgs(varargin{:});
            
            if (isempty(options.nodes))
                % Plot the entire graph
                nodes = 1:g.numNodes;
                [i,j,a] = find(g.adjacency);
                i = i';
                j = j';
                a = a';
            else
                % Plot sub-graph of the node set "nodes"
                nodes = options.nodes;
                g1 = g.subgraph(nodes);
                [i,j,a] = find(g1.adjacency);
                i = nodes(i);
                j = nodes(j);
            end
            
            try
                %-----------------------
                % Open file
                %-----------------------
                outputDir = fileparts(file);
                if (~exist(outputDir, 'dir'))
                    mkdir(outputDir);
                end
                f = fopen(file, 'w');
                
                %-----------------------
                % Write data to file
                %-----------------------
                
                % Header
                fprintf(f, 'graph G {\n');

                % Node data
                n = numel(nodes);
                fprintf(f, '%d [fixedsize="true", width="%.2f", height="%.2f", fontsize="%d"]\n', ...
                    [nodes; repmat([options.width; options.height; options.fontSize], [1 n])]);

                % Edge data; labels = edge weights
                if (options.graphType == graph.api.GraphType.UNDIRECTED)
                    fprintf(f, '%d -- %d\n', [i; j]);
                else
                    fprintf(f, '%d -- %d [label="%.2g"]\n', [i; j; a]);
                end
                
                % Footer
                fprintf(f, '}\n');
                
                %-----------------------
                % Close file
                %-----------------------
                closeFile(f);
            catch e
                if (obj.logger.errorEnabled)
                    closeFile(f);
                    obj.logger.error('Failed to save to dot file %s: %s\n', file, e.message);
                end
            end
        end
    end
    
    %======================== METHODS =================================
    methods (Static, Access = private)
        function args = parseWriteArgs(varargin)
            % Parse input arguments to the write() method.
            p                   = inputParser;
            p.FunctionName      = 'WriterDot';
            p.KeepUnmatched     = true;
            p.StructExpand      = true;
            
            p.addParamValue('graphType', graph.api.GraphType.UNDIRECTED, @(x)(isa(x, graph.api.GraphType)));
            p.addParamValue('fontSize', 8, @isNonnegativeIntegral);
            p.addParamValue('width', 0.4, @(x)(x > 0));
            p.addParamValue('height', 0.4, @(x)(x > 0));
            p.addParamValue('nodes', [], @isnumeric);
            
            p.parse(varargin{:});
            args = p.Results;
        end
    end
    
end
