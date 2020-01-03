classdef (Hidden, Sealed) TvInitialGuessFourier < amg.tv.TvInitialGuess
    %TVINITIALGUESS Build Fourier initial guess for test vectors.
    %   This interface builds a set of initial TVs at a level.
    %
    %   See also: TVFACTORY, LEVEL.
    
    %======================== IMPL: TvInitialGuess ====================
    methods
        function x = build(obj, level, K) %#ok<MANU>
            % Generate K relaxed TVs, starting from Fourier components node
            % coordinates of increasing frequencies. Works for grids only
            % (or not?!).
            
            % Generate powers of coordinates. Each row  (p1..pd) of the
            % powers array corresponds to the TV x1^p1 x ... x xd^pd, where
            % (x1..xd) is the node coordinate. Omitting the constant vector
            % and sorting by ascending sum_i(pi) (=ascending TV
            % smoothness).
            coord = level.g.coord;
            dim = cols(coord);
            if (dim == 1)
                powers = (2:K+1)';
            else
                p = harmonics(dim,K);                       % Contains much more than K TVs to choose from -- wasteful but simple
                powers = sortrows([p, sum(p,2)], dim+1);    % Add a third helper column to sort by
                powers = powers(2:end,1:dim);                   % Remove helper column and omit first row = constant vector
            end
            
            % Generate the TVs - Fourier components that satisfy Neumann
            % B.C. on [0,1]^dim
            x = ones(level.g.numNodes, K);
            size(coord)
            for i = 1:K
                for d = 1:dim
                    % X = cos(2*pi*x1*p1) x ... x cos(2*pi*xd*pd) x
                    % non-symmetric terms so that not all X's have
                    % vanishing derivatives at the middle of the domain
                    xd = coord(:,d);
                    x(:,i) = x(:,i) .* cos(pi*xd.*powers(i,d));
                end
            end
            
            % Normalize to unit size
            n = level.g.numNodes;
            x = x./repmat(sqrt(sum(x.^2)/n), n, 1);
        end
    end
end
