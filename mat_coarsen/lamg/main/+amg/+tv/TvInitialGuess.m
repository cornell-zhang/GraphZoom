classdef (Hidden) TvInitialGuess < handle
    %TVINITIALGUESS Build an initial guess for test vectors.
    %   This interface builds a set of initial TVs at a level.
    %
    %   See also: PROBLEM, LEVEL, PROBLEMSETUPLAPLACIAN.
    
    %======================== METHODS =================================
    methods (Abstract)
        x = build(obj, level, K)
        % Return K TV initial guesses in the columns of X.
    end
end
