classdef (Hidden, Sealed) RunnerComponentDecomp < graph.runner.Runner
    %RUNNERWRITEMAT A runner that writes the graph to file in MAT format.
    %   This class is useful for graph format conversion. Use a READER to
    %   load it and this runner to save it in MAT format, which is the
    %   easiest for MATLAB to deal with.
    %
    %   See also: RUNNER.
    
    %=========================== PROPERTIES ==============================
    properties (Constant, GetAccess = private)
        logger = core.logging.Logger.getInstance('graph.runner.RunnerComponentDecomp')
    end
    
    properties (GetAccess = private, SetAccess = private)
        writer                  % Writes graphs to output dir
    end
    properties (GetAccess = private, SetAccess = public)
        minSize = 5             % Min component size to save
    end
    
    %=========================== CONSTRUCTORS ============================
    methods
        function obj = RunnerComponentDecomp(outputDir)
            %Runner constructor. Initializer writer.
            obj.writer = graph.runner.RunnerWriteMat(outputDir);
        end
    end
    
    %======================== IMPL: Runner ===============================
    methods
        function fieldNames = fieldNames(obj) %#ok<MANU>
            % Return a cell array of result element labels.
            fieldNames = { 'success' };
        end
        
        function [result, details, updatedGraph] = run(obj, g, dummy) %#ok
            % Decomposte a graph G into components. Save each component to a
            % MAT file. Return a success flag.
            
            % Default output values
            result = 0;
            details = [];
            updatedGraph = [];
 
            [numComponents, components] = obj.getLargeComponents(g, obj.minSize);
            
            if (numComponents == 1)
                [result, details] = obj.writer.run(g);
            elseif (numComponents > 0)
                for c = components
                    % Save each component separately
                    [result, details] = obj.writer.run(c{1});
                    if (result == 0)
                        break;
                    end
                end
            end
        end
    end
    
    %=========================== PRIVATE METHODS =========================
    methods (Access = private)
        function [numComponents, comp] = getLargeComponents(obj, g, minSize) %#ok<MANU>
            % Compute a graph's large connected components (of size >= minSize).

            % Calculate connected components
            s = components(g.adjacency);
            numComponents = max(s);

            if (numComponents == 1)
                % Singly-connected graph, don't return any components
                comp = {};
            else
                % Multi-connected graph, return components of size >=
                % minSize
                comp        = cell(1,numComponents);
                numLarge    = 0;
                n           = find(hist(s,max(s)) >= minSize);
                for i = n
                    index    = find(s == i);
                    numLarge = numLarge + 1;
                    subGraph = g.subgraph(index, sprintf('component-%d', numLarge)); %#ok
                    comp{numLarge} = subGraph;
                end
                comp = comp(1:numLarge);
            end
        end % getLargeComponents()
    end
    
end

