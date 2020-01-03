classdef (Sealed) NbhrFinderFactory < handle
    %GENERATORFACTORY A factory of neighbor finder services.
    %   This class produces template grid graph neighbor finder instances
    %   based on input options.
    %
    %   See also: GRAPH.
    
    %======================== METHODS =================================
    methods
        function instance = newInstance(obj, options) %#ok<MANU>
            % Returns a new neibhbor findiner instance based on the input
            % options parsed from VARARGIN.
            switch (options.bc)
                case 'neumann'
                    % Neumann B.C.
                    instance = graph.generator.NbhrFinderNeumann(options);
                case 'periodic'
                    % Periodic B.C.
                    instance = graph.generator.NbhrFinderPeriodic(options);
                otherwise
                    error('MATLAB:GeneratorFactory:newInstance:InputArg', 'Unknown grid boundary condition ''%s''', options.bc);
            end
        end
    end
end
