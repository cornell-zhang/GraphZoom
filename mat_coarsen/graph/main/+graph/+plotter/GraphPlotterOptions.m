classdef (Sealed) GraphPlotterOptions % A value object
    %GRAPHPLOTTEROPTIONS Graph plot options.
    %   Centralizes 2-D graph drawing options for class GRAPHPLOTTER.
    %
    %   See also: GRAPHPLOTTER.
    
    %=========================== PROPERTIES ==============================
    properties (Constant, GetAccess = private)
        logger = core.logging.Logger.getInstance('graph.api.GraphPlotterOptions')
    end
    
    properties (GetAccess = public, SetAccess = public)
        radius = 0.8                % Vertex circle radius
        edgeFraction = 0.5          % Fraction of distance along edge to print weight at
        fontSize = 20               % Text font size (vertex + edge texts)
        fontWeight = 'normal'       % Text font weight (vertex + edge texts)
        faceColor = [0.8 0.8 0.8]   % Node face color (RGB)
        edgeColor = 'none'          % Node edge color (RGB)
    end
    
    %=========================== CONSTRUCTORS ============================
    methods
        function obj = GraphPlotterOptions(varargin)
            %----------------------
            % Parse input arguments
            %----------------------
            parser                  = inputParser;
            parser.FunctionName     = 'GraphPlotterOptions';
            parser.KeepUnmatched    = true;
            
            parser.addParamValue ('radius', obj.radius, @(x)(x >= 0));
            parser.addParamValue ('edgeFraction', obj.edgeFraction, @(x)((x >= 0) && (x <= 1)));
            parser.addParamValue ('fontSize', obj.fontSize, @isNonnegativeIntegral);
            parser.addParamValue ('fontWeight', obj.fontWeight, @(x)(isempty(x) || any(strcmpi(x,{'plain', 'bold', 'italic'}))));
            parser.addParamValue ('faceColor', [0.8 0.8 0.8], @(x)(ischar(x) || isnumeric(x)));
            parser.addParamValue ('edgeColor', [0.8 0.8 0.8], @(x)(ischar(x) || isnumeric(x)));
            
            parser.parse(varargin{:});
            args = parser.Results;
            
            % Copy parsed fields to object
            fields = fieldnames(args);
            for i = 1:length(fields)
                field = fields{i};
                obj.(field) = args.(field);
            end
        end
    end
    
    %=========================== METHODS =================================
    methods
        function obj = build(obj)
            % Builder pattern. Validate and finish building options based
            % on property settings here. This method should only be called
            % by class GraphPlotter (like package-visibility in Java).
        end
    end
    
    %=========================== PRIVATE METHODS =========================
    
    methods (Static, Access = private)
    end
    
end
