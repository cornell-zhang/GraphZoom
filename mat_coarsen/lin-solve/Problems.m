classdef (Sealed) Problems < handle
    %SOLVERS A factory of Problem instacnes.
    %   This class provides factory methods (functors) to instantiate
    %   different graph problems.
    %
    %   See also: SOLVER, PROBLEM.
    
    %=========================== PROPERTIES ===========================
    properties (Constant, GetAccess = public)
        logger              = core.logging.Logger.getInstance('Problems')
        MIN_WEIGHT_ALLOWED  = -1e-5      % Default value for negative weight threshold in Laplacian problems
    end
    
    %======================== METHODS =================================
    methods (Static)
        function problem = laplacian(g, b)
            % Create a laplacian linear problem A*x=b.
            problem = lin.api.Problem(g.laplacian, b, g);
        end
        
        function problem = laplacianHomogeneous(g)
            % Create a homogeneous laplacian linear problem A*x=0 from the
            % graph g. Adapt g's adjacency if necessary.
            g = Problems.toLaplacian(g, Problems.MIN_WEIGHT_ALLOWED);
            problem = lin.api.Problem(g.laplacian, zeros(g.numNodes, 1), g);
        end
                
        function g = laplacianGraphFromTestInstance(key)
            % Load a test graph instance and adapt adjacency to have a proper Laplacian problem if necessary.
            g = Problems.laplacianHomogeneous(Graphs.testInstance(key)).g;
        end
        
        function problem = resistance(g)
            % Create a resistance problem A*x = b from the graph g. Adapt
            % g's adjacency if necessary.
            %
            % This is an effective resistance problem A*x=b,
            % b(s)=1,b(t)=-1,otherwise 0. Pick s,t in the same component so
            % that b is compatible. Assuming singly connected graph.
            
            g = Problems.toLaplacian(g, Problems.MIN_WEIGHT_ALLOWED);
            % Assuming singly connected graph
            s = 1;
            t = 2;
            b = zeros(g.numNodes, 1);
            b([t s]) = [1 -1];
            problem = lin.api.Problem(g.laplacian, b, g);
        end
        
        function problem = randomRhs(g)
            % Create a Laplacian problem A*x = b from the graph g where b = rand. Adapt
            % g's adjacency if necessary. Assuming singly connected graph.
            g = Problems.toLaplacian(g, Problems.MIN_WEIGHT_ALLOWED);
            b = rand(g.numNodes, 1);
            b = b - mean(b);
            problem = lin.api.Problem(g.laplacian, b, g);
        end

        function downloadCollection(outputDir, varargin)
            % downloadCollection(outputDir) downloads the entire test
            % collection into GLOBAL.data_out_dir.outputdir. Split
            % multi-connected graphs to their components.
            %
            % downloadCollection(outputDir, minEdges, maxEdges) downloads graphs with
            % at least minEdges and at most maxEdges edges.
            %
            % downloadCollection(outputDir, minEdges) is the same as
            % downloadCollection(outputDir, minEdges,  Inf).
            if (numel(varargin) < 1)
                minEdges = 150;
            else
                minEdges = varargin{1};
            end
            if (numel(varargin) < 2)
                maxEdges = Inf;
            else
                maxEdges = varargin{2};
            end
            if (minEdges < 310)
                graphConvert(2, 310, {'mat', 'uf'}, outputDir,  'filter', 'component-decompose', 'minSize', 2);
            end
            graphConvert(minEdges, maxEdges, {'mat', 'uf'}, outputDir,  'filter', 'component-decompose', 'minSize', 150);
        end
    end
    
    methods (Static, Access = private)
        function gNew = toLaplacian(g, minWeightAllowed)
            % Create a Laplacian linear problem A*x=b. Adapt the graph
            % adjacency matrix if needed so that the resulting matrix is an
            % "acceptable" Laplacian. Problems with large positive
            % off-diagonals above the minWeightAllowed threshold are
            % replaced by their sparsity patterns.
            W = g.adjacency;
            d = diag(W);
            W = W - diag(d);  % Remove diagonal elements
            if (~isempty(find(d, 1)))
                % g.adjacency has diagonal entries ==> might have been
                % loaded from the UF collection, but is might not be
                % non-SPD. Use the sparsity pattern of W's graph as our
                % problem.
                W = spones(W);
                if (Problems.logger.infoEnabled)
                    Problems.logger.info('Problem load: found diagonal entries, using sparsity pattern(W)\n');
                end
            elseif (~isempty(find(W < 0, 1)))
                % Negative edge weights exist. Check that their total sum
                % is not too large relative to the maximum element in every
                % row
                bound       = max(abs(W));
                [i,j,w]     = find(W); 
                k           = find(w < 0);
                Wnegative   = sparse(i(k),j(k),w(k),size(W,1),size(W,1));
                sumNegative = sum(Wnegative);
                if (~isempty(find(sumNegative < minWeightAllowed*bound, 1)))                    
                    % W has large negative edge weights, use |W| instead.
                    % (Small off-diagonals can naturally arise in
                    % higher-order Laplacian discretizations and are OK.)
                    W = abs(W);
                    if (Problems.logger.infoEnabled)
                        Problems.logger.info('Problem load: found relatively large (< %.1e) negative edge weights, using |W|\n', minWeightAllowed);
                    end
                end
            end
            % Zero-out small elements that are beyond machine precision and
            % will lead to artificial round-off problems.
            maxWeight = max(nonzeros(W))*ones(size(W,1),1);
            %maxWeight = max(abs(W));
            threshold = sqrt(eps); %3*sqrt(eps); %1e-14;
            W = filterSmallEntries(W, maxWeight, threshold, 'abs', 'min');
            
            % Create a new graph instance, since it is immutable
            gNew = graph.api.Graph.newInstanceFromMetadata(g.metadata, 'adjacency', W, g.coord);
            % Just in case we disconnected the graph by filtering small
            % entries, take the largest component
            gNew = largestComponent(gNew);
        end
    end
end
