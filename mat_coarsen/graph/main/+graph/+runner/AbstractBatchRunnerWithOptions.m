classdef AbstractBatchRunnerWithOptions < handle
    %BATCHRUNNERCYCLE A base class for cycle tests on a batch of test
    %graphs.
    %   This is the main abstract utility class used to run the multilevel
    %   cycle for a set of test graph instances.
    %
    %   See also: MULTILEVELSETUP, CYCLE, RUNNERCYCLEACF.
    
    %=========================== PROPERTIES ==============================
    properties (Constant, GetAccess = protected)
        PRINTER_FACTORY = graph.printer.PrinterFactory
    end
    properties (Constant, GetAccess = private)
        logger          = core.logging.Logger.getInstance('graph.runner.AbstractBatchRunnerWithOptions')
    end
    
    properties (GetAccess = protected, SetAccess = private)
        runOptions      % Holds batch run and print options
    end
    properties (GetAccess = private, SetAccess = private)
        batchRunner = graph.runner.BatchRunner      % Runs the entire batch of graph instances
        randomSeed      % Holds multigrid setup and cycle options
        runner          % Runs on each graph instance
        outputDir       % Dir to save output files under
        dt              % Date string
    end
    
    %======================== CONSTRUCTORS ============================
    methods (Access = protected)
        function obj = AbstractBatchRunnerWithOptions(varargin)
            % Costruct a batch runner from input options. VARARGIN contains
            % both run and multileve options.
            import amg.runner.*;
            global GLOBAL_VARS;
            
            % Read input arguments
            obj.runOptions = graph.runner.AbstractBatchRunnerWithOptions.parseRunOptions(varargin{:});
            obj.batchRunner.checkPointFrequency = 20;
            obj.runner     = obj.newRunner(obj.runOptions, varargin{:});
            
            % Initializations
            obj.outputDir  = strcat(GLOBAL_VARS.out_dir, '/', obj.runOptions.outputDir);
            if (~isempty(obj.runOptions.outputFile))
                obj.runOptions.outputFileName = strcat(obj.outputDir, '/', obj.runOptions.outputFile);
                core.logging.Logger.setFile(strcat(obj.runOptions.outputFileName, '.log'));
            end
        end
    end
    
    %======================== ABSTRACT METHODS / HOOKS ================
    methods (Abstract, Access = protected)
        runner = newRunner(obj, runOptions, varargin)
        % Create a runner instance that executes the cycle-related business
        % logic on graph problems.
        
        printer = newPrinter(obj, result, fmt, f, varargin)
        % Create a printer from custom run options.
    end
    
    %======================== METHODS =================================
    methods (Sealed)
        function [result, solverContext] = run(obj)
            % Run ACF experiments on the test graph set and report results.
            
            % Initializations
            diaryFile   = strcat(obj.outputDir, '/cycle_results_log.txt');
            % Can only be done in the c-tor
            %             runOptionsOld = obj.runOptions; if (nargout >= 2)
            %                 obj.runOptions.clearWhenDone = false;
            %             end
            
            if (obj.runOptions.save)
                diary off;
                create_dir(diaryFile, 'file');
                if (exist(diaryFile,'file'))
                    delete(diaryFile);
                end
                eval(sprintf('diary %s', diaryFile));
            end
            
            % Fix random seed
            if (~isempty(obj.runOptions.randomSeed))
                setRandomSeed(obj.runOptions.randomSeed);
            end
            
            % Batch run
            result = obj.batchRun();
            
            % Report and output results
            obj.postRun(result);
            if (obj.runOptions.print)
                obj.printResults(result);
            end
            
            if (obj.runOptions.save)
                diary off;
            end
            if (nargout >= 2)
                % A convenience output alias for single-graph runs: first
                % result's setup object
                if (result.numRuns == 0)
                    solverContext = [];
                else
                    solverContext = result.details{1};
                end
            end
            %obj.runOptions = runOptionsOld;
            
            if (obj.runOptions.sendMail)
                if (obj.runOptions.svnCommit)
                    committed = 'yes';
                else
                    committed = 'no';
                end
                sendmail('livne@uchicago.edu', 'LAMG Run Complete', ...
                    sprintf('Output directory: %s\nCommited to SVN? %s', obj.outputDir, ...
                    committed), ...
                    {diaryFile});
            end
            if (obj.runOptions.svnCommit)
                system(sprintf('svn add %s', obj.outputDir));
                system(sprintf('svn commit -m "Batch run auto-commit" %s', obj.outputDir));
            end
        end
        
        function printer = defaultPrinter(obj, result, varargin)
            % Create a printer from current run options.
            printer = obj.newPrinter(result, obj.runOptions.format, obj.runOptions.outputFile, varargin{:});
        end
        
        function printResults(obj, result, varargin)
            % Create a printer from custom run options.
            if (isempty(obj.runOptions.outputFile))
                f = 1;
            else
                f = fopen(obj.runOptions.outputFileName, 'w');
            end
            printer = obj.newPrinter(result, obj.runOptions.format, f, varargin{:});
            printer.run();
            if (~isempty(obj.runOptions.outputFile))
                fclose(f);
            end
        end
    end
    
    %======================== PRIVATE METHODS =========================
    methods (Access = protected)
        % Hooks
        function postRun(obj, result) %#ok
            % Perform after run is over, but when diary is still on.
        end
    end
    
    methods (Static, Access = private)
        function args = parseRunOptions(varargin)
            % Parse input arguments.
            global GLOBAL_VARS;
            p                   = inputParser;
            p.FunctionName      = 'AbstractBatchRunnerWithOptions';
            p.KeepUnmatched     = true;
            p.StructExpand      = true;
            
            p.addParamValue('inputDir', 'lap', @ischar);
            p.addParamValue('format', 'text', @(x)(any(strcmp(x, {'text', 'html', 'latex'}))));
            p.addParamValue('outputFile', [], @ischar);
            p.addParamValue('minNodes', 2, @isnumeric);
            p.addParamValue('maxNodes', Inf, @isnumeric);
            p.addParamValue('minEdges', 1, @isnumeric);
            p.addParamValue('maxEdges', Inf, @isnumeric);
            p.addParamValue('selectedIndices', [], @isnumeric);
            p.addParamValue('graph', [], @(x)(isa(x, 'graph.api.Graph')));
            p.addParamValue('key', [], @ischar);
            p.addParamValue('index', [GLOBAL_VARS.data_dir '/lap_index.mat'], @ischar); % Graph index file
            p.addParamValue('keyRegexp', [], @ischar);
            p.addParamValue('load', false, @islogical);
            p.addParamValue('save', false, @islogical);
            p.addParamValue('print', true, @islogical);
            p.addParamValue('sendMail', false, @islogical);
            p.addParamValue('svnCommit', false, @islogical);
            p.addParamValue('clearWhenDone', true, @islogical); % Clears large setup objects after each problem solve in a batch run
            p.addParamValue('output', 'minimal', @(x)(any(strcmp(x,{'minimal', 'full'}))));
            p.addParamValue('randomSeed', [], @isPositiveIntegral);
            p.addParamValue('solvers', {}, @iscell);
            % Die on exception in solver runner classes (set to true for
            % debugging)
            p.addParamValue('dieOnException', false, @islogical);
            % Output dir relative to global out_dir
            p.addParamValue('outputDir', [], @ischar);
            % Printer total width
            p.addParamValue('totalWidth', [], @isPositiveIntegral);
            
            % Parameters for run parallelization on multiple nodes. Running
            % numRuns with runId = 1..numRuns. Each runs the graphs whose
            % ID satisfies ID mod numRuns = runId-1.
            p.addParamValue('numRuns', 1, @isPositiveIntegral);
            p.addParamValue('runId', 1, @isPositiveIntegral);
            
            p.parse(varargin{:});
            args = p.Results;
            
            % Validation rules / dependent property setting
            if (~isempty(args.outputFile))
                args.save = true;
            end
            
            % Add date identifier string if output dir name not specified
            % to ensure directory uniqueness
            if (isempty(args.outputDir))
                args.outputDir = datestr(now, 'yyyy-mm-dd');
            end
            % Append run ID to output dir in a parallel run
            if (args.numRuns > 1)
                args.outputDir = strcat(args.outputDir, sprintf('_%03d', args.runId));
            end
        end
    end
    
    methods (Access = private)
        function [batchReader, selectedGraphs] = buildBatchReader(obj)
            % Load graphs using a batch reader
            global GLOBAL_VARS;
            
            if (~isempty(obj.runOptions.graph))
                % Run a single graph instance directly from a Graph run
                % option
                batchReader = graph.reader.BatchReader;
                batchReader.add('graph', obj.runOptions.graph);
                selectedGraphs = 1;
            elseif (~isempty(obj.runOptions.key))
                % Run a single graph instance by key
                [dummy, batchReader] = Graphs.testInstance(obj.runOptions.key); %#ok
                clear dummy;
                selectedGraphs = 1;
            elseif (~isempty(obj.runOptions.index))
                % Read a data index
                a = load(obj.runOptions.index);
                batchReader = a.r;
                % Constrain by #node, #edge ranges
                n = batchReader.getNumNodes;
                m = batchReader.getNumEdges;
                match = (n >= obj.runOptions.minNodes) & (n <= obj.runOptions.maxNodes) & ...
                    (m >= obj.runOptions.minEdges) & (m <= obj.runOptions.maxEdges);
                if (~isempty(obj.runOptions.keyRegexp))
                    % Further constrain by key regular expression
                    match = match & batchReader.fieldMatches('key', obj.runOptions.keyRegexp);
                end
                index = find(match);
                [dummy, i] = sort(m(index)); %#ok
                clear dummy;
                selectedGraphs = index(i);
                
                % Restrict to runs within our run ID
                selectedGraphs = selectedGraphs(obj.runOptions.runId:obj.runOptions.numRuns:end);
            else
                % Load instances from file system into a batch reader
                batchReader = graph.reader.BatchReader;
                batchReader.add('dir', [GLOBAL_VARS.data_dir '/' obj.runOptions.inputDir]);
                n = batchReader.getNumNodes;
                m = batchReader.getNumEdges;
                match = (n >= obj.runOptions.minNodes) & (n <= obj.runOptions.maxNodes) & ...
                    (m >= obj.runOptions.minEdges) & (m <= obj.runOptions.maxEdges);
                index = find(match);
                [dummy, i] = sort(m(index)); %#ok
                clear dummy;
                selectedGraphs = index(i);
                %                 selectedGraphs =
                %                 graph.api.GraphUtil.getGraphsWithEdgesBetween(...
                %                     batchReader, obj.runOptions.minEdges,
                %                     obj.runOptions.maxEdges);
                if (~isempty(obj.runOptions.selectedIndices))
                    selectedGraphs = selectedGraphs(obj.runOptions.selectedIndices);
                    fprintf('Restricting runs to indices %d\n', selectedGraphs);
                end
                
                % Restrict to runs within our run ID
                selectedGraphs = selectedGraphs(obj.runOptions.runId:obj.runOptions.numRuns:end);
            end
        end
        
        function result = batchRun(obj)
            % Core function that runs experiments.
            
            % Initializations
            %global GLOBAL_VARS;
            [batchReader, selectedGraphs] = obj.buildBatchReader();
            resultFile  = strcat(obj.outputDir, '/cycle_results.mat');
            
            if (~obj.runOptions.load)
                tstart = tic;
                if (obj.runOptions.print)
                    fprintf('Starting run at %s\n', datestr(now));
                    if (~isempty(obj.runOptions.randomSeed))
                        fprintf('Random seed = %d\n', obj.runOptions.randomSeed);
                    end
                end
                
                % Run multigrid on graphs in batch mode
                result = obj.batchRunner.run(...
                    batchReader, obj.runner, selectedGraphs);
                
                % Save results under a date-dependent directory
                if (obj.runOptions.save)
                    create_dir(resultFile, 'file');
                    save(resultFile, 'result');
                end
                if (obj.runOptions.print)
                    fprintf('Finished run at %s run time = %.2f min\n', datestr(now), toc(tstart)/60);
                end
            else
                % Load results from a previous file
                result = load(resultFile);
                result = result.result;
            end
        end
        
    end
end
