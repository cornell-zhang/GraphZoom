classdef (Hidden, Sealed) TvInitialGuessPoly < amg.tv.TvInitialGuess
    %TVINITIALGUESS Build polynomial initial guess for test vectors.
    %   This interface builds a set of initial TVs at a level.
    %
    %   See also: TVFACTORY, LEVEL.
    
    %======================== IMPL: TvInitialGuess ====================
    methods
        function x = build(obj, level, K)
            % Generate K relaxed TVs, starting from polynomials of node
            % coordinates of increasing degrees. Requires node coordinates
            % to be available for the graph instance. This means that nu
            % can be smaller than in relaxedTvs(), because the initial
            % guesses are much relaxer than random vectors.
            
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
            
            % Generate the TVs
            x = ones(level.size, K);
            for i = 1:K
                for d = 1:dim
                    % X = x1^p1 x ... x xd^pd
                    xd = coord(:,d);
                    x(:,i) = x(:,i) .* xd.^powers(i,d);
                    %x(:,i) = x(:,i) .* xd.^powers(i,d) .*
                    %xd.^2.*(1-xd).^2);
                end
            end
            
            % Normalize to unit size
            x = x./repmat(sqrt(sum(x.^2)/level.size), level.size, 1);
        end
    end
end
