classdef (Sealed) Graphs < handle
    %GRAPHS Graph mother object.
    %   This is a top-level utility class that contains useful static
    %   factory methods that produce graph instances. (A method object).
    %
    %   See also: GRAPH, GRAPHUTIL.
    
    %=========================== PROPERTIES ==============================
    properties (Constant, GetAccess = private)
        GENERATOR       = graph.generator.GeneratorFactory    % Graph generator mother object
    end
    
    %=========================== CONSTRUCTORS =========================
    methods (Access = private)
        function obj = Graphs
            %Hide constructor in utility class.
        end
    end
    
    %======================== METHODS =================================
    methods (Static)
        function [g, batchReader] = testInstance(key)
            % Return the test instance G under the MAT data dir with the
            % unique identifier (key) KEY.
            
            config;
            global GLOBAL_VARS;
            
            parts = textscan(key,'%s','delimiter','/');
            parts = parts{1}';
            group = strconcatdelim('/', parts{1:end-1});
            
            batchReader = graph.reader.BatchReader;
            batchReader.add('group', group, 'file', [GLOBAL_VARS.data_dir '/' key '.mat']);
            
            if (batchReader.size == 0)
                warning('MATLAB:testInstance:InputArg', 'Could not find test instance under key ''%s''', key);
                g = [];
            else
                g = batchReader.read(1);
            end
        end
        
        function g = grid(gridType, n, varargin)
            % Return a D-dimensional grid graph of size N=(N(1),...,N(D)).
            options = graph.generator.GeneratorFactory.parseArgs('grid', varargin{:});
            switch (gridType)
                case 'fe2-negative',
                    g = Graphs.fe2Negative(n, varargin{:});
                case 'fe-stretched',
                    g = Graphs.feStretched(n, varargin{:});
                case 'mehrstellen',
                    g = Graphs.mehrstellen(n, varargin{:});
                case 'anis-sym',
                    g = Graphs.anisSym(n, options.alpha, options.eps, varargin{:});
                case 'anis-aligned',
                    g = Graphs.anisAligned(n, options.alpha, options.eps, varargin{:});
                case 'biharmonic',
                    g = Graphs.biharmonic(n, varargin{:});
                otherwise
                    g = Graphs.GENERATOR.newInstance('grid', 'gridType', gridType, 'n', n, varargin{:});
            end
        end
        
        function g1 = randomlyPerturb(g0, e)
            % Add small e-magnitude random near-full graph to g0.
            E  = abs(sprandsym(g0.numNodes, 0.8));
            E  = E-diag(diag(E));
            g1 = Graphs.fromAdjacency(g0.adjacency + e*E);
        end
        
        function g = feStretched(n, varargin)
            % 2nd-order FE 2-D Laplace discretization with negative
            % weights. Infinitely stretched quads (hx->0 )
            if (numel(n) ~= 2)
                error('MATLAB:Graphs:feStreched:InputArg', 'mehrstellen discretization currently supports 2-D problems only');
            end
            g = AmgTestUtil.GENERATOR.newInstance('grid', 'gridType', ...
                'fe2-feStreched', 'n', n, 'stencil', ...
                [ ...
                [-1 -1  1]; ...
                [-1  0  4]; ...
                [-1  1  1]; ...
                [ 0 -1 -2]; ...
                [ 0  1 -2]; ...
                [ 1 -1  1]; ...
                [ 1  0  4]; ...
                [ 1  1  1]; ...
                ], ...
                varargin{:});
        end
        
        function g = fe2Negative(n, varargin)
            % 2nd-order FE 2-D Laplace discretization with negative
            % weights.
            if (numel(n) ~= 2)
                error('MATLAB:Graphs:mehrstellen:InputArg', 'mehrstellen discretization currently supports 2-D problems only');
            end
            g = AmgTestUtil.GENERATOR.newInstance('grid', 'gridType', ...
                'fe2-negative', 'n', n, 'stencil', ...
                [ ...
                [-1 -1 -1]; ...
                [-1  0  4]; ...
                [-1  1 -1]; ...
                [ 0 -1  4]; ...
                [ 0  1  4]; ...
                [ 1 -1 -1]; ...
                [ 1  0  4]; ...
                [ 1  1 -1]; ...
                ], ...
                varargin{:});
        end
        
        function g = mehrstellen(n, varargin)
            % 4th-order Mehrstellen 2-D Laplace discretization.
            if (numel(n) ~= 2)
                error('MATLAB:Graphs:mehrstellen:InputArg', 'mehrstellen discretization currently supports 2-D problems only');
            end
            g = AmgTestUtil.GENERATOR.newInstance('grid', 'gridType', ...
                'mehrstellen', 'n', n, 'stencil', ...
                [ ...
                [-1 -1  1]; ...
                [-1  0  4]; ...
                [-1  1  1]; ...
                [ 0 -1  4]; ...
                [ 0  1  4]; ...
                [ 1 -1  1]; ...
                [ 1  0  4]; ...
                [ 1  1  1]; ...
                ], ...
                varargin{:});
        end
        
        function g = anisSym(n, alpha, e, varargin)
            % 2nd order anisotropic rotated 2-D Laplace discretization.
            % Symmeric uxy discretization. alpha=angle, e=anisotropy
            % coefficient.
            if (numel(n) ~= 2)
                error('MATLAB:Graphs:anisSym:InputArg', 'the anisotropic rotated discretization currently supports 2-D problems only');
            end
            
            A = cos(alpha)^2 + e*sin(alpha)^2;
            B = (1-e)*sin(2*alpha);
            C = sin(alpha)^2 + e*cos(alpha)^2;
            
            Uxx = [ ...
                [ 0 -1  1]; ...
                [ 0  1  1]; ...
                ];
            
            Uyy = [ ...
                [-1  0  1]; ...
                [ 1  0  1]; ...
                ];
            
            Uxy = [ ...
                [-1 -1  1/4]; ...
                [-1  1 -1/4]; ...
                [ 1 -1 -1/4]; ...
                [ 1  1  1/4]; ...
                ];
            
            s = [ ...
                Graphs.stencilTimes(A,Uxx); ...
                Graphs.stencilTimes(B,Uxy); ...
                Graphs.stencilTimes(C,Uyy); ...
                ];
            g = AmgTestUtil.GENERATOR.newInstance('grid', 'gridType', ...
                'anis-sym', 'n', n, 'stencil', s, varargin{:});
        end
        
        function g = anisAligned(n, alpha, e, varargin)
            % 2nd order anisotropic rotated 2-D Laplace discretization. uxy
            % discretization aligned with NW-SE direction. alpha=angle,
            % e=anisotropy coefficient.
            if (numel(n) ~= 2)
                error('MATLAB:Graphs:anisAligned:InputArg', 'the anisotropic rotated discretization currently supports 2-D problems only');
            end
            
            A = cos(alpha)^2 + e*sin(alpha)^2;
            B = (1-e)*sin(2*alpha);
            C = sin(alpha)^2 + e*cos(alpha)^2;
            
            Uxx = [ ...
                [ 0 -1  1]; ...
                [ 0  1  1]; ...
                ];
            
            Uyy = [ ...
                [-1  0  1]; ...
                [ 1  0  1]; ...
                ];
            
            Uxy = [ ...
                [-1 -1  1/2]; ...
                [-1  0 -1/2]; ...
                [ 0 -1 -1/2]; ...
                ...
                [ 1  1  1/2]; ...
                [ 1  0 -1/2]; ...
                [ 0  1 -1/2]; ...
                ];
            
            s = [ ...
                Graphs.stencilTimes(A,Uxx); ...
                Graphs.stencilTimes(B,Uxy); ...
                Graphs.stencilTimes(C,Uyy); ...
                ];
            g = AmgTestUtil.GENERATOR.newInstance('grid', 'gridType', ...
                'anis-sym', 'n', n, 'stencil', s, varargin{:});
        end
        
        function g = biharmonic(n, varargin)
            % 2nd-order FD 2-D biharmonic discretization with negative
            % weights. Infinitely stretched quads (hx->0 )
            if (numel(n) > 2)
                error('MATLAB:Graphs:biharmonic:InputArg', 'biharmonic discretization currently supports 1-D and 2-D problems only');
            elseif (numel(n) == 1)
                % 2-D biharmonic
                g = AmgTestUtil.GENERATOR.newInstance('grid', 'gridType', ...
                    'biharmonic', 'n', n, 'stencil', ...
                    [ ...
                    [-2  -1]; ...
                    [-1   4]; ...
                    [ 1   4]; ...
                    [ 2  -1]; ...
                    ], ...
                    varargin{:});
            else
                % 2-D biharmonic
                g = AmgTestUtil.GENERATOR.newInstance('grid', 'gridType', ...
                    'biharmonic', 'n', n, 'stencil', ...
                    [ ...
                    [ 0 -1  8]; ...
                    [ 0  1  8]; ...
                    [-1  0  8]; ...
                    [ 1  0  8]; ...
                    [-1 -1 -2]; ...
                    [-1  1 -2]; ...
                    [ 1 -1 -2]; ...
                    [ 1  1 -2]; ...
                    [ 0 -2 -1]; ...
                    [ 0  2 -1]; ...
                    [-2  0 -1]; ...
                    [ 2  0 -1]; ...
                    ], ...
                    varargin{:});
            end
        end
        
        function g = path(n, varargin)
            % Return a path graph of size N with two weakly connected
            % components whose connection strength is E.
            if (numel(varargin) < 1)
                e = 1.0;
            else
                e = varargin{1};
            end
            g = AmgTestUtil.GENERATOR.newInstance('path', 'n', n, 'e', e);
        end
        
        function g = sun(n)
            % Return a sun graph of size N.
            g = AmgTestUtil.GENERATOR.newInstance('sun', 'n', n);
        end
        
        function g = complete(n)
            % Return the complete graph of size N.
            e = spones(ones(n,1));
            k = (0:n-1)';
            coord = 0.5*[cos(2*pi*k/n) sin(2*pi*k/n)]; % Place nodes on unit circles
            g = Graphs.fromAdjacency((speye(n) - e*e')/n, coord);
        end
        
        function g = gridWithExtraEdge(gridType, n, varargin)
            % A grid with extra global link of strength extraEdgeWeight.
            options = graph.generator.GeneratorFactory.parseArgs('grid', varargin{:});
            grid = Graphs.grid(gridType, n, varargin{:});
            %d = length(n); % Grid dimension
            
            % Add global link
            A = grid.adjacency;
            N = size(A,1);
            u = n(1)+2;
            v = N - prod(n(1:end-1)) - 1;
            A(u,v) = options.extraEdgeWeight;
            g = Graphs.fromAdjacency(A, grid.coord);
        end
        
        function g = fromAdjacency(A, varargin)
            % Create an undirected graph from an adjacency matrix A and
            % optional coordinates.
            if (numel(varargin) >= 1)
                coord = varargin{1};
            else
                coord = [];
            end
            g = graph.api.Graph.newNamedInstance('graph', 'adjacency', A, coord);
        end
        
        function g = union(g1, g2, varargin)
            % Union two graphs g1 and g2.
            if (numel(varargin) >= 1)
                g = AmgTestUtil.GENERATOR.newInstance('union', 'g1', g1, 'g2', g2, 'e', varargin{1});
            else
                g = AmgTestUtil.GENERATOR.newInstance('union', 'g1', g1, 'g2', g2);
            end
        end
        
        function s = stencilTimes(a, s)
            % Multiply all stencil coefficients by a.
            s = [s(:,1:2) a*s(:,3)];
        end
        
        function g = pathPlusSmallRandom(n, eps, p)
            % A 1-D grid to which a random graph with small weights is
            % added.
            pat = Graphs.grid('fd', n, 'normalized', true);
            R = abs(triu(sprandsym(n, p)));
            R = R+R';
            g = Graphs.fromAdjacency(pat.adjacency + eps*R, pat.coord);
        end
        
        function g = pathPlusSmallGrid(n, eps, d)
            % A 1-D grid of size n^d to which a d-dimensional nx...xn graph
            % with small weights is added.
            path = Graphs.grid('fd', n^d, 'normalized', true);
            small = Graphs.grid('fd', n*ones(d,1), 'normalized', true);
            g = Graphs.fromAdjacency(path.adjacency + eps*small.adjacency, path.coord);
        end
        
        function g = pathPlusComplete(n, m, eps)
            % pathPlusComplete(N,M,EPS) returns A 2-D FE grid of size N and
            % unit weights to which a complete sub-graph of size M<=N^2
            % with edge weights EPS is added.
            path = Graphs.grid('fe', [n n], 'normalized', true);
            N = path.numNodes;
            complete = Graphs.complete(m);
            % Augment complete block to path's size
            [i,j,w] = find(complete.adjacency);
            R = sparse(i,j,w,N,N);
            g = Graphs.fromAdjacency(path.adjacency + eps*R, path.coord);
        end
        
        function g = sunPath(pathSize, numSuns, numSats, eps)
            % A normalized path graph of size PATHSIZE, of which the first
            % NUMSUNS nodes are suns, plus NUMSATS satellites, each of
            % which is connected to all suns with random weights of size
            % EPS.
            p = Graphs.path(pathSize);
            %[isat,jsat] = ndgrid((1:numSats)+pathSize,1:pathSize);
            [isat,jsat] = ndgrid((1:numSats)+pathSize,1:min(pathSize,numSuns));
            nzList = [p.edgesAndWeights; [isat(:) jsat(:) eps*ones(numel(isat),1)]];
            %nzList = [p.edgesAndWeights; [isat(:) jsat(:) eps*(0.5 + 0.5*rand(numel(isat),1))]];
            coord = [[(0:pathSize-1)' zeros(pathSize,1)]; [(0:numSats-1)' ones(numSats,1)]];
            n = pathSize + numSats;
            W = sparse(nzList(:,1), nzList(:,2), nzList(:,3), n, n)';
            g = Graphs.fromAdjacency(W, coord);
        end
        
        function g = sunPathRandom(numSuns, numSats, satDegree, eps)
            % G=sunPathRandom(NUMSUNS,NUMSATS,SATDEGREE,EPS) generates
            % a sun path graph with NUMSUNS, plus NUMSATS satellites, each
            % of which connected to SATDEGREE random suns with weight EPS.
            p = Graphs.path(numSuns);
            j = zeros(1, numSats*satDegree);
            for k = 1:numSats,
                j((k-1)*satDegree+1:k*satDegree) = randperm(numSuns, satDegree);
            end
            [dummy, i] = ndgrid(1:satDegree, 1:numSats); %#ok
            clear dummy;
            nz = [p.edgesAndWeights; [i(:)+numSuns j' repmat(eps, numel(j), 1)]];
            n = numSuns + numSats; 
            W = sparse(nz(:,1), nz(:,2), nz(:,3), n, n);
            coord = [[(0:numSuns-1)' zeros(numSuns,1)]; [(0:numSats-1)' ones(numSats,1)]];
            g = Graphs.fromAdjacency(W', coord);
        end
    end
end
