classdef (Sealed) RelaxFactory < amg.api.HasArgs
    %RELAXFACTORY A factory of relaxation service objects.
    %   This class produces RELAX instances based on input options.
    %
    %   See also: RELAX.
    
    %======================== CONSTRUCTORS ============================
    methods
        function obj = RelaxFactory(varargin)
            % Initialize a relaxation factory. OPTIONS contains
            % construction arguments for instances returned from
            % newInstance().
            obj = obj@amg.api.HasArgs(varargin{:});
        end
    end
    
    %======================== IMPL: ProblemDependentFactory ===========
    methods
        function instance = newInstance(obj, level, varargin)
            % Returns a new relaxation scheme instance for the level
            % level.
            
            if (numel(varargin) >= 1)
                relaxType = varargin{1};
            else
                relaxType = obj.options.relaxType;
            end
            switch (relaxType)
                case 'gs'
                    % Gauss-Seidel
                    %instance = amg.relax.RelaxGaussSeidel(level, obj.options.relaxOmega, obj.options.relaxAdaptive);
                    instance = amg.relax.RelaxGaussSeidelOptimized(level);
                case 'sgs'
                    % Symmetric Gauss-Seidel
                    instance = amg.relax.RelaxSymmetricGaussSeidel(level, obj.options.relaxOmega, obj.options.relaxAdaptive);
                case 'gs-random'
                    % Gauss-Seidel
                    instance = amg.relax.RelaxGaussSeidelRandom(level, obj.options.relaxOmega, obj.options.relaxAdaptive);
                case 'jacobi'
                    % Weighted Jacobi
                    instance = amg.relax.RelaxJacobi(level, obj.options.relaxOmega, obj.options.relaxAdaptive);
                case 'elimination'
                    % Exact elimination of f nodes in terms of c nodes
                    instance = amg.relax.RelaxElimination(level, varargin{2}, varargin{3}, varargin{4});
                otherwise
                    error('MATLAB:RelaxFactory:newInstance:InputArg', 'Unknown relaxation type ''%s''', relaxType);
            end
        end
    end
    
    %======================== IMPL: HasArgs ===========================
    methods (Access = protected)
        function args = parseArgs(obj, varargin) %#ok<MANU>
            % Parse a variable argument list into an ARGS struct. Usually
            % implemented using an INPUTPARSER.
            p                   = inputParser;
            p.FunctionName      = 'RelaxFactory';
            p.KeepUnmatched     = true;
            p.StructExpand      = true;
            
            %p.addParamValue('relaxAdaptive', false, @islogical);  % Run local adaptive sweeps or not
            
            p.parse(varargin{:});
            args = p.Results;
        end
    end
end
