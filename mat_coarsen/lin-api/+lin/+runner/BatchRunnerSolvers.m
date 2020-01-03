classdef (Sealed) BatchRunnerSolvers < graph.runner.AbstractBatchRunnerWithOptions
    %BatchRunnerSolvers Compares linear solvers for a batch of test graphs.
    %   This is the main utility class used to run the multilevel cycle for
    %   a set of test graph instances.
    %
    %   See also: MULTILEVELSETUP, CYCLE, RUNNERCYCLEACF.
    
    %======================== CONSTRUCTORS ============================
    methods
        function obj = BatchRunnerSolvers(varargin)
            % Costruct a batch runner from input options. VARARGIN contains
            % both run and multileve options.
            obj = obj@graph.runner.AbstractBatchRunnerWithOptions(varargin{:});
        end
    end
    
    %======================== IMPL: AbstractBatchRunner ===============
    methods (Access = protected)
        function runner = newRunner(obj, runOptions, varargin) %#ok<MANU>
            % Create a runner instance that executes the cycle-related
            % business logic on graph problems.
            
            % Resistance can be too easy for PCG if there are local
            % eigenvectors (e.g., A*x=b where b=lam*x and
            % b=lam*x=[1,-1,0,...0]). Use random RHS to ensure non-trivial
            % solution components.
            %runner = lin.runner.RunnerSolvers(@Problems.resistance, runOptions);
            runner = lin.runner.RunnerSolvers(@Problems.randomRhs, runOptions);
            for n = runOptions.solvers
                name = n{:};
                solver = Solvers.newSolver(name, varargin{:});
                runner.addSolver(name, solver);
            end
        end
        
        function printer = newPrinter(obj, result, fmt, f, varargin)
            % Create a printer from custom run options.
            printer = graph.runner.AbstractBatchRunnerWithOptions.PRINTER_FACTORY.newInstance(...
                fmt, result, f, varargin{:});
            printer.addIndexColumn('#', 3);
            if (~isempty(obj.runOptions.totalWidth))
                printer.totalWidth = obj.runOptions.totalWidth;
            end
            printer.addColumn('Group'   , 's', 'field'   , 'metadata.key',      'width', 30);
            printer.addColumn('#Nodes'  , 'd', 'field'   , 'metadata.numNodes', 'width',  8);
            printer.addColumn('#Edges'  , 'd', 'field'   , 'metadata.numEdges', 'width',  9);
            if (~isempty(find(strcmp(result.fieldNames, 'lamgNumLevels'),1)))
            printer.addColumn('#lev'    , 'd', 'field'   , ...
                sprintf('data(%d)', result.fieldColumn('lamgNumLevels')), 'width',  5);
            printer.addColumn('ACF'     , 'f', 'field'   , ...
                sprintf('data(%d)', result.fieldColumn('lamgAcf')),      'width',  7, 'precision', 3);
            printer.addColumn('tSetup'  , 'e', 'field'   , ...
                sprintf('data(%d)', result.fieldColumn('lamgTSetup')),   'width',  9, 'precision', 1);
            printer.addColumn('tSolve'  , 'e', 'field'   , ...
                sprintf('data(%d)', result.fieldColumn('lamgTSolve')),   'width',  9, 'precision', 1);
            end
            % LAMG total time: use hard-coded setup, solve columns for now
            if (result.numFields >= 8)
                printer.addColumn('tTotal'  , 'e', 'function'   , ...
                    @(metadata, data, details)(data(7)+10*data(8)),  'width',  9, 'precision', 1);
            end
        end
        
    end
    
    %======================== PRIVATE METHODS =========================
    methods (Access = protected)
        % Hooks
        function postRun(obj, result)
            % Perform after run is over, but when diary is still on.
            result.sortRows(result.fieldColumn('numEdges')); % Sort graphs by size
            plotResultBundle(result, 10, [], 0, obj.runOptions.solvers);
        end
    end
end
