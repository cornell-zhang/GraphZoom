classdef (Sealed) FitterFactory < handle
    %FITTERFACTORY A factory of regression model fitters.
    %   This class produces Fitter instances.
    %
    %   See also: FITTER.
    
    %======================== METHODS =================================
    methods
        function instance = newInstance(obj, type, varargin) %#ok<MANU>
            % Returns a new generator graph instance based on the input
            % options parsed from VARARGIN.
            switch (type)
                case 'griddy-ls'
                    % Least-squares regression, griddy algorithm
                    instance  = amg.energy.FitterGriddyLs(varargin{:});
                case 'grid'
                    % Maximum norm regression, griddy algorithm
                    instance  = amg.energy.FitterGriddyMax(varargin{:});
                otherwise
                    error('MATLAB:FitterFactory:newInstance:InputArg', 'Unknown fitter type ''%s''', type);
            end
        end
    end
end
