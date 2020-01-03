classdef (Enumeration, Sealed) CoarseningState < int8
    %COARSENINGTYPE Coarsening strategy type.
    %   This is an enumeration of MULTILEVELSETUP coarsening states used
    %   during the setup phase.
    %
    %   See also: COARSENINGSTRATEGY, MULTILEVELSETUP.
    
    %======================== CONSTANTS ===============================
    enumeration
        FINEST(0)                   % Finest level
        ELIMINATION(1)              % Eliminate 0-, 1-, 2- degree and other low-impact nodes
        AGG(2)                     % AGG coarsening level (caliber-1 P + Galerkin + energy correction)
        DONE_COARSENING(3)          % Terminal state at which no further coarsening is possible or needed
    end
    
    %======================== METHODS =================================
    methods
        function d = details(obj)
            % Returns a new CoarseStrategy instance for the MultilevelSetup
            % target object TARGET corresponding to the coarsening state
            % STATE.
            switch (obj)
                case amg.setup.CoarseningState.FINEST,
                    d.name = 'FINEST';
                    d.isElimination = false;
                case amg.setup.CoarseningState.ELIMINATION,
                    d.name = 'ELIM';
                    d.isElimination = true;
                case amg.setup.CoarseningState.AGG,
                    d.name = 'AGG';
                    d.isElimination = false;
                case amg.setup.CoarseningState.DONE_COARSENING,
                    d.name = 'DONE_COARSENING';
                    d.isElimination = false;
                otherwise
                    error('MATLAB:CoarseningState:newInstance:InputArg', 'Unknown coarsening state ''%s''', obj);
            end
        end
    end
    
    methods (Static)
        function handlers = newHandlerMap(options, factory)
            % Return a map of state-to-state-handler
            % (=coarsening-state-to-coarsening-strategy).
            handlers = containers.Map('KeyType', 'int32', 'ValueType', 'any');
            for i = int32(amg.setup.CoarseningState.FINEST):int32(amg.setup.CoarseningState.AGG)
                handlers(i) = factory.newHandler(amg.setup.CoarseningState(i), options);
            end
        end        
    end
end
