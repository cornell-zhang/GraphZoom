classdef SingleLevelOperator < handle
    %SINGLELEVELOPERATOR An operator of a single level.
    %   This is a base interface for all uni-level operations (e.g.
    %   discrete operator and relaxation).
    
    %======================== MEMBERS =================================
    properties (GetAccess = protected, SetAccess = private)
        level             % Processing level in context
    end
    
    %======================== CONSTRUCTORS ============================
    methods (Access = protected)
        function obj = SingleLevelOperator(level)
            % Initialize an operator at level LEVEL.
            obj.level = level;
        end
    end
    
end
