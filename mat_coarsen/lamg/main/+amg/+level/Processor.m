classdef Processor < handle
    %PROCESSOR Multigrid cycle level processor.
    %   This interface encapsulates the business logic of level processing
    %   within the multigrid cycle. class is designed for extension.
    %
    %   See also: SETUP, CYCLINGSTRATEGY.
    
    %======================== PROPERTIES ==============================
    properties (GetAccess = public, SetAccess = protected)
        coarsest    % Index of coarsest level. Can be dynamically set.
    end
    
    %======================== METHODS =================================
    methods (Abstract)
        initialize(obj, l, numLevels, initialGuess)
        % Run at the beginning of an NUMLEVELS-level cycle at the finest
        % level L. INITIALGUESS is the initial value of the iterate passed
        % into the cycle. The RESULT field retrieves the iterate at the end
        % of the cycle.
        
        coarsestProcess(obj, l)
        % Run at the coarsest level L.
        
        preProcess(obj, l)
        % Execute at level L right before switching to the next-coarser
        % level L+1.
        
        postProcess(obj, l)
        % Execute at level L right before switching to the next-finer level
        % L-1.
        
        x = result(obj, l)
        % Return the cycle result X at level l. Normally called by Cycle
        % with l=finest level.
    end
    
    methods % Hooks
        function postCycle(obj, l) %#ok
            % Execute at the finest level L at the end of the cycle.
        end
    end
end
