classdef (Hidden, Sealed) TvInitialGuessFromFine < amg.tv.TvInitialGuess
    %TVINITIALGUESS Build initial guess for test vectors from the
    %next-finer level.
    %   This interface builds a set of initial TVs at a level x = T*x^f
    %   where x^f = TVs of next-finer level.
    %
    %   See also: TVFACTORY, LEVEL.
    
    %======================== IMPL: TvInitialGuess ====================
    methods
        function x = build(obj, level, dummy) %#ok
            % x = T*xf
            x = level.T * level.fineLevel.x;
        end
    end
end
