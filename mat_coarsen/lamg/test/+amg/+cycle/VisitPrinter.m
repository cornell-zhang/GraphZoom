classdef (Sealed, Hidden) VisitPrinter < amg.level.Processor
    %VISITPRINTER Prints level visitation for cycle index logic testing.
    %   This class prints level visitation events within a cycle.
    %
    %   See also: CYCLESTRATEGY.
    
    %======================== MEMBERS =================================
    properties (Constant, GetAccess = private)
        logger = core.logging.Logger.getInstance('amg.setup.VisitPrinter')
    end
    
    properties (GetAccess = public, SetAccess = private)
        numVisits           % Level visitation counters (numVisits(l) = # times level l was visited from the next-finer level)
        numTransfers        % transfers(l) = # times inter-level transfers (l+1->l) are called
    end
    
    %======================== IMPL: Processor =========================
    methods
        function initialize(obj, l, numLevels, dummy1, dummy2) %#ok
            % Run at the beginning of a cycle at the finest level L.
            if (obj.logger.traceEnabled)
                obj.logger.trace('### Cycle at level %d, #levels=%d ###\n', l, numLevels);
            end
            obj.numVisits       = zeros(1,numLevels);
            obj.numTransfers    = zeros(1,numLevels);
        end
        
        function coarsestProcess(obj, l)
            % Run at the coarsest level L.
            obj.numVisits(l) = obj.numVisits(l)+1;
            obj.printState(l, 'coarsest');
        end
        
        function preProcess(obj, l)
            % Execute at level L right before switching to the next-coarser
            % level L+1.
            c = l+1;
            obj.numVisits(l) = obj.numVisits(l)+1;
            obj.numTransfers(c) = obj.numTransfers(c)+1;
            obj.printState(l, 'pre');
        end
        
        function postProcess(obj, l)
            % Execute at level L right before switching to the next-finer
            % level L-1.
            obj.printState(l, 'post');
            c = l+1;
            obj.numTransfers(c) = obj.numTransfers(c)+1;
        end
        
        function [x, r] = result(obj, l) %#ok
            % Return the cycle result at level l. Normally called by Cycle
            % with l=finest level. % No result returned here.
            x = [];
            r = [];
        end
    end
    
    %======================== PRIVATE METHODS =========================
    methods (Access = private)
        function printState(obj, l, action)
            % Print the current cycle processing action and state.
            if (obj.logger.traceEnabled)
                obj.logger.trace('Level %d %-9s', l, action);
                if (strcmp(action, 'pre'))
                    obj.logger.trace('%d ', obj.numVisits);
                end
                obj.logger.trace('\n');
            end
        end
    end
end