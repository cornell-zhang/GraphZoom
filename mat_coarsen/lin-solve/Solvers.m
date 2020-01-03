classdef (Sealed) Solvers < handle
    %SOLVERS A factory of Solver instacnes.
    %   This is the main class for interacting with the LAMG library code.
    %   New solvers added to the library should be registered here.
    %
    %   See also: SOLVER.
    
    %======================== METHODS =================================
    methods (Static)
        function solver = newSolver(name, varargin)
            % Create a solver instance of type TYPE with input options
            % to be parsed from VARARGIN.
            switch (name)
                case 'lamg',
                    % Lean Algebraic Multigrid (LAMG) - best options
                    defaultOptions = amg.api.Options;
                    %varargin{:}
                    [options, varargin] = Solvers.parseLamgOptions(defaultOptions, varargin{:});
                    solver = amg.solve.SolverLamg(options, varargin{:});
                case 'lamgFlat',
                    % LAMG with flat energy correction
                    defaultOptions = amg.api.Options;
                    defaultOptions.minRes = false;
                    defaultOptions.energyCorrectionType = 'flat';
                    defaultOptions.rhsCorrectionFactor = 4/3;
                    defaultOptions.combinedIterates = 1;
                    [options, varargin] = Solvers.parseLamgOptions(defaultOptions, varargin{:});
                    solver = amg.solve.SolverLamg(options, varargin{:});
                case 'direct',
                    % MATLAB's direct solver (UMFPack)
                    solver = lin.solve.SolverDirect(varargin{:});
                case 'cmg',
                    % Combinatorial Multigrid (CMG)
                    defaultOptions = amg.api.Options;
                    [options, varargin] = Solvers.parseLamgOptions(defaultOptions, varargin{:});
                    solver = lin.solve.SolverCmg(options, varargin{:});
                case 'agmg',
                    % Notay's AGMG (an AMG variant for grid graphs)
                    solver = amg.solve.SolverAgmg(varargin{:});
                otherwise
                    error('MATLAB:LevelFactory:newInstance:InputArg', 'Unknown solver ''%s''', name);
            end
        end
        
        function [result, solverContext, batchRunner] = runSolvers(varargin)
            %RUNSOLVERS Compute solver performance for graph instances.
            %   [STATS, READER, PRINTER] = RUNSOLVERS(OPTIONS) prints a table of
            %   multilevel convergence statistics for all graph instances under the
            %   directory 'mat' relative to the GLOBAL_VARS.DATA_DIR dir. STATS holds
            %   the statistics. READER is the batch reader used for reading DIR; you
            %   may obtain an individual graph instance using a READER.READ() call. The
            %   results are also saved under the GLOBAL_VARS.OUT_DIR/<current_date>
            %   directory. PRINTER is the printer used to print the result table.
            %
            %   OPTIONS a struct contains run options. Recognized multi-level options
            %   (amg.api.Options) are used during the setup and solution phases. Other
            %   options include
            %
            %   	minEdges, maxEdges    Minimum/maximum number of edges in
            %                             considered graphs. Default=0/3000.
            %
            %       format                'text' or 'html'. Determines the printout
            %                             format. Default: 'text'.
            %
            %       key                   Specific problem key. If non-empty,
            %                             only this problem will be run.
            %
            %       load                  A flag. If true, the stats will be loaded
            %                             from the existing MAT file dump under the
            %                             GLOBAL_VARS.OUT_DIR directory, and an empty
            %                             BATCHREADER will be returned. Default: false.
            %
            %       save                  A flag. If true, the stats will be saved
            %                             under GLOBAL_VARS.OUT_DIR directory. Default:
            %                             false.
            %
            %   See also: OPTIONS, GRAPHSTATS, GRAPHPLOT, MULTILEVELSETUP, CYCLE.
            warning('off', 'MATLAB:pcg:tooSmallTolerance');
            warning('off', 'MATLAB:CMG:hierarchy:stagnation');
            config;
            batchRunner = lin.runner.BatchRunnerSolvers(varargin{:});
            [result, solverContext] = batchRunner.run();
            warning('on', 'MATLAB:pcg:tooSmallTolerance');
            warning('on', 'MATLAB:CMG:hierarchy:stagnation');
        end
    end
    
    %=========================== PRIVATE METHODS==========================
    methods (Static, Access = private)
        function [options, varargin] = parseLamgOptions(defaultOptions, varargin)
            % Parse method arguments into LAMG options and additional
            % arguments to override them in the SolverLamg() call.
            
            if ((numel(varargin) >= 1) && isa(varargin{1}, 'amg.api.Options'))
                options = varargin{1};
                varargin = varargin(2:end);
            else
                options = defaultOptions;
            end
        end
    end
    
end
