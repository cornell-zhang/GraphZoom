classdef (Hidden, Sealed) ReaderFactory < handle
    %READERFACTORY A factory of graph reader objects.
    %   This class produces READER instances based on the graph input
    %   format.
    %
    %   See also: READER, FORMAT.
    
    %=========================== PROPERTIES ==============================
    properties (GetAccess = private, SetAccess = private)
        readerGenerated         % Generated graph dummy reader
        readerMat               % MATLAB format graph instance reader
        readerUf                % UF graph instance reader
        readerChaco             % Chaco format graph instance reader
        readerDimacs            % Second DIMACS Challenge format graph instance reader
        readerPlain             % GraphViz plain text reader
        readerCompressedColumn     % Compressed column format text reader
    end
    
    %=========================== CONSTRUCTORS ============================
    methods
        function obj = ReaderFactory
            %Reader factory constructor. Initializes cached readers.
            ufIndex             = ufget;
            obj.readerGenerated = graph.reader.ReaderGenerated();
            obj.readerMat       = graph.reader.ReaderMat();
            obj.readerUf        = graph.reader.ReaderUf(ufIndex);
            obj.readerChaco     = graph.reader.ReaderChaco();
            obj.readerDimacs  	= graph.reader.ReaderDimacs();
            obj.readerPlain     = graph.reader.ReaderGraphVizPlain();
            obj.readerCompressedColumn = graph.reader.ReaderCompressedColumn();
        end
    end
    
    %======================== METHODS =================================
    methods
        function instance = newInstance(obj, formatType, dummy) %#ok
            % A factory method that returns a new graph reader instance for
            % input format FORMATTYPE. The struct OPTIONS contains optional
            % construction arguments.
            switch (formatType)
                case graph.api.GraphFormat.GENERATED,
                    instance = obj.readerGenerated;
                case graph.api.GraphFormat.MAT,
                    instance = obj.readerMat;
                case graph.api.GraphFormat.UF,
                    instance = obj.readerUf;
                case graph.api.GraphFormat.CHACO,
                    instance = obj.readerChaco;
                case graph.api.GraphFormat.DIMACS,
                    instance = obj.readerDimacs;
                case graph.api.GraphFormat.PLAIN,
                    instance = obj.readerPlain;
                case graph.api.GraphFormat.COMPRESSED_COLUMN,
                    instance = obj.readerCompressedColumn;
                otherwise
                    error('MATLAB:ReaderFactory:newInstance:InputArg', 'Unsupported graph input format''%s''', char(formatType));
            end
        end
    end
end
