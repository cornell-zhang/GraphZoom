classdef (Sealed) CoarseningStrategyFactory < handle
    %CoarseningStrategyFactory A factory of CoarseningStrategy objects.
    %   This class produces CoarseningStrategy instances.
    %
    %   See also: CoarseningStrategy.
    
    %======================== METHODS =================================
    methods
        function instance = newHandler(obj, state, options) %#ok<MANU>
            % Returns a new CoarseStrategy instance for the MultilevelSetup
            % target object TARGET corresponding to the coarsening state
            % STATE.
            switch (state)
                case amg.setup.CoarseningState.FINEST,
                    instance = amg.setup.CoarseningStrategyFinest(options);
                case amg.setup.CoarseningState.ELIMINATION,
                    instance = amg.setup.CoarseningStrategyElimination(options);
                case amg.setup.CoarseningState.AGG,
                    instance = amg.setup.CoarseningStrategyAgg(options);
                case amg.setup.CoarseningState.DONE_COARSENING,
                    instance = []; % No handler needed
                otherwise
                    error('MATLAB:CoarseningState:newInstance:InputArg', 'Unknown coarsening state ''%s''',state);
            end
        end
    end
end
