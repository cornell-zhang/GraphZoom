classdef (Sealed) LevelFactory < handle
    %LEVELFACTORY A factory of Level objects.
    %   This class produces LEVEL instances.
    %
    %   See also: LEVEL.
    
    %======================== METHODS =================================
    methods
        function instance = newInstance(obj, type, index, state, relaxFactory, K, varargin) %#ok<MANU>
            % Initialize a level of type TYPE for the linear problem A*x=0 from input
            % options.
            import amg.level.LevelType
            
            switch (type)
                case LevelType.FINEST,
                    % Finest level
                    instance = amg.level.LevelFinest(type, index, state, relaxFactory, K, varargin{:});
                case LevelType.ELIMINATION,
                    % Obtained by exact low-degree node elimination
                    instance = amg.level.LevelElimination(type, index, state, relaxFactory, K, varargin{:});
                case LevelType.AGG,
                    % Obtained by AGG coarsening
                    instance = amg.level.LevelAgg(type, index, state, relaxFactory, K, varargin{:});
                otherwise
                    error('MATLAB:LevelFactory:newInstance:InputArg', 'Unknown level type ''%s''', type);
            end
        end
    end
end
