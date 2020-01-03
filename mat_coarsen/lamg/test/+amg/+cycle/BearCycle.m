classdef (Sealed, Hidden) BearCycle < handle
    %BEARCYCLE Recursive multigrid cycle for cycle index logic testing.
    %   This class only increments level visitation counters like a cycle;
    % it does contain have the actual cycle logic.
    
    %======================== MEMBERS =================================
    properties (Constant, GetAccess = private)
        logger = core.logging.Logger.getInstance('amg.setup.BearCycle')
    end
    
    properties (GetAccess = public, SetAccess = private)
        numLevels           % # cycle levels
        cycleIndex          % Cycle index
        numVisits           % Level visitation counters (numVisits(l) = # times level l was visited from the next-finer level)
    end
    
    %======================== CONSTRUCTORS ============================
    methods
        function obj = BearCycle(numLevels, cycleIndex)
            % Create a cycle simulation.
            obj.numLevels   = numLevels;
            obj.cycleIndex  = cycleIndex;
        end
    end
    
    %======================== METHODS =================================
    methods
        function cycle(obj, finest)
            % The main call that executes a cycle at level FINEST with
            % finest RHS B and an initial guess X. If B is not specified,
            % FINEST must be 1 and B is set to SETUP.LEVELS{FINEST}.B.
            obj.cycleAtLevel(finest, finest);
        end
    end
    
    %======================== PRIVATE METHODS =========================
    methods (Access = private)
        function cycleAtLevel(obj, l, finest)
            % Execute a cycle at level L. FINEST is the index of the finest
            % level in the cycle. Recursively calls itself with the
            % next-coarser level until NUM_LEVELS is reached.
            
            % Initialize level visitation counters
            L = obj.numLevels;
            if (l == finest)
                obj.numVisits = zeros(1,L-1);
            end
            
            if (l == L)
                % Coarsest level
                if (obj.logger.traceEnabled)
                    obj.printState(l, 'coarsest');
                    %disp(obj.numVisits);
                end
            else
                c = l+1;
                if (l == 1)
                    maxVisits = 1;
                else
                    maxVisits = obj.cycleIndex*obj.numVisits(l-1);
                end
                while (obj.numVisits(l) < maxVisits)
                    obj.numVisits(l) = obj.numVisits(l)+1;
                    obj.printState(l, 'pre');
                    %--- Coarse-grid correction ---
                    obj.cycleAtLevel(c, finest);
                    obj.printState(l, 'post');
                end
            end
        end
    end
    
    methods (Access = private)
        function printState(obj, l, stage)
            if (obj.logger.traceEnabled)
                obj.logger.trace('Level %d %-9s', l, stage);
                if (strcmp(stage, 'pre'))
                    obj.logger.trace('%d ', obj.numVisits);
                end
                obj.logger.trace('\n');
            end
        end
    end
end