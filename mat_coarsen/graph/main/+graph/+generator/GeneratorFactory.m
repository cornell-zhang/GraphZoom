classdef (Sealed) GeneratorFactory < handle
    %GENERATORFACTORY A factory of generated graph instances.
    %   This class produces template graph instances based on input options.
    %
    %   See also: GRAPH.
    
    %======================== METHODS =================================
    methods
        function instance = newInstance(obj, type, varargin) %#ok<MANU>
            % Returns a new generator graph instance based on the input
            % options parsed from VARARGIN.
            options = graph.generator.GeneratorFactory.parseArgs(type, varargin{:});

            switch (options.type)
                case 'sun'
                    % 1-D grid with two components whose connection stength is e
                    generator   = graph.generator.GeneratorSun(options);
                case 'path'
                    % 1-D grid with two components whose connection stength is e
                    generator   = graph.generator.GeneratorLoosePath(options);
                case 'union'
                    % Union two graphs.
                    generator   = graph.generator.GeneratorUnion(options.g1, options.g2, options.e);
                case 'grid'
                    switch (options.gridType)
                        case 'fd'
                            % Uniform grid, FD discretization, 2nd order
                            generator   = graph.generator.GeneratorGridFd(options);
                        case 'fd4'
                            % Uniform grid, FD discretization, 4th order
                            generator   = graph.generator.GeneratorGridFd4(options);
                        case 'fe'
                            % Uniform grid, FE, 2nd order
                            generator   = graph.generator.GeneratorGridFe(options);
                        otherwise
                            % General stencil
                            generator   = graph.generator.GeneratorGridStencil(options, options.gridType);
                    end
                otherwise
                    error('MATLAB:GeneratorFactory:newInstance:InputArg', 'Unknown generated graph type ''%s''', options.type);
            end
            instance = generator.build();
        end
    end
    
    %======================== PRIVATE METHODS =========================
    methods (Static, Access = public)
        function options = parseArgs(type, varargin)
            % Parse options to the newInstance() method.
            p                   = inputParser;
            p.FunctionName      = 'GeneratorFactory';
            p.KeepUnmatched     = true;
            p.StructExpand      = true;
            
            p.addRequired  ('type', @(x)(any(strcmp(x,{'union', 'path', 'grid', 'sun'}))));
            %p.addParamValue('gridType', [], @(x)(any(strcmp(x,{'fd', 'fd4', 'fe', 'mehrstellen', 'fe2-negative'}))));
            p.addParamValue('gridType', [], @ischar);
            p.addParamValue('bc', 'neumann', @(x)(any(strcmp(x,{'neumann', 'periodic'}))));
            p.addParamValue('h', [], @isnumeric); % Grid meshsize
            p.addParamValue('n', [], @isPositiveIntegral); % Grid size
            p.addParamValue('e', 1.0, @isnumeric); % Anisotropy parameter
            p.addParamValue('normalized', false, @islogical); % Normalize Laplacian or not
            p.addParamValue('stencil', 1.0, @isnumeric); % Grid stencil
            p.addParamValue('alpha', [], @isnumeric); % rotation angle
            p.addParamValue('eps', [], @(x)(x>=0)); % anisotropy coefficient
            p.addParamValue('extraEdgeWeight', 1.0, @isnumeric); % anisotropy coefficient
            p.addParamValue('g1', [], @(x)(isa(x, 'graph.api.Graph')));
            p.addParamValue('g2', [], @(x)(isa(x, 'graph.api.Graph')));

            p.parse(type, varargin{:});
            options = p.Results;
        end
    end
end
