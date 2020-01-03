classdef (Hidden, Sealed) WriterFactory < handle
    %WRITERFACTORY A factory of graph writer objects.
    %   This class produces WRITER instances based on the desired graph
    %   output format.
    %
    %   See also: WRITER, FORMAT.
    
    %=========================== PROPERTIES ==============================
    properties (GetAccess = private, SetAccess = private)
        writerMat               % MATLAB format graph instance writer
        writerUf                % UF graph instance writer
        writerChaco             % Chaco format graph instance writer
        writerDimacs2           % Second DIMACS Challenge format graph instance writer
        writerDot               % dot graph plotting language writer
    end
    
    %=========================== CONSTRUCTORS ============================
    methods
        function obj = WriterFactory
            %Writer factory constructor. Initializes cached writers.
            %ufIndex             = ufget;
            obj.writerMat       = graph.writer.WriterMat();
            %obj.writerUf        = graph.writer.WriterUf(ufIndex);
            %obj.writerChaco     = graph.writer.WriterChaco();
            %obj.writerDimacs2  	= graph.writer.WriterDimacs2();
            obj.writerDot       = graph.writer.WriterDot();
        end
    end
    %======================== METHODS =================================
    methods
        function instance = newInstance(obj, formatType, dummy) %#ok
            % A factory method that returns a new graph writer instance for
            % input format FORMATTYPE. The struct OPTIONS contains optional
            % construction arguments.
            switch (formatType)
                case graph.api.GraphFormat.MAT,
                    instance = obj.writerMat;
                    %                 case graph.api.GraphFormat.UF,
                    %                     instance = obj.writerUf;
                    %                 case graph.api.GraphFormat.CHACO,
                    %                     instance = obj.writerChaco;
                    %                 case graph.api.GraphFormat.DIMACS2,
                    %                     instance = obj.writerDimacs2;
                case graph.api.GraphFormat.DOT,
                    instance = obj.writerDot;
                otherwise
                    error('MATLAB:WriterFactory:load:InputArg', 'Unsupported graph output format''%s''', char(formatType));
            end
        end
    end
end
