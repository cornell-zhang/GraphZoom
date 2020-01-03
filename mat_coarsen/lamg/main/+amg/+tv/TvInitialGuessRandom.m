classdef (Hidden, Sealed) TvInitialGuessRandom < amg.tv.TvInitialGuess
    %TVINITIALGUESS Build random initial guess for test vectors.
    %   This interface builds a set of initial TVs at a level.
    %
    %   See also: TVFACTORY, LEVEL.
    
    %======================== IMPL: TvInitialGuess ====================
    methods
        function x = build(obj, level, K) %#ok<MANU>
            % Random start
            x = 2*rand(level.g.numNodes, K)-1;
        end
    end
end
