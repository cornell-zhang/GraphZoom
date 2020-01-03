classdef (Sealed) WofComputer < lin.api.IterativeIndexComputer
    %WOFCOMPUTER Relaxation WOF.
    %   This class computes the Wipe-off Factor (WOF) of a relaxation
    %   method.
    %
    %   See also: RUNNER, ITERATIVEMETHOD.
    
    %=========================== PROPERTIES ==============================
    properties (Constant, GetAccess = private)
        logger = core.logging.Logger.getInstance('amg.runner.WofComputer')
    end
    
    properties (Dependent)
        nu  % # iterations to compute WOF for
    end
    
    %======================== CONSTRUCTORS ============================
    methods
        function obj = WofComputer(varargin)
            % Initialize a relaxation factory. OPTIONS contains
            % construction arguments for instances returned from
            % newInstance().
            obj = obj@lin.api.IterativeIndexComputer(varargin{:});
            
            % Add our specific options
            thisOptions = amg.runner.WofComputer.parseArgs(varargin{:});
            obj.options = optionsOverride(obj.options, thisOptions);
        end
    end
    
    %======================== GET & SET ===============================
    methods
        function nu = get.nu(obj)
            % Return the number of iterations to compute WOF for.
            nu = obj.options.nu;
        end
    end

    %======================== PRIVATE METHODS =========================
    methods (Static, Access = private)
        function options = parseArgs(varargin)
            % Parse input options.
            p                   = inputParser;
            p.FunctionName      = 'WofComputer';
            p.KeepUnmatched     = true;
            p.StructExpand      = true;
            
            % # iterations to compute WOF for
            p.addParamValue('nu', 5, @isPositiveIntegral);
            p.addParamValue('numTrials', 5, @isPositiveIntegral);
            
            p.parse(varargin{:});
            options = p.Results;
        end
    end
    
    %======================== IMPL: IterativeIndexComputer ============
    methods (Access = protected)
        function [wof, reductionHistory, x, stats] = runIterations(obj, problem, iterativeMethod, x, r)
            % Run a sequence of iterations of ITERATIVEMETHOD and estimate
            % its wipe-off factor (INDEX).
            
            reductionHistory    = zeros(obj.options.numTrials, obj.options.nu);
            cumulativeHistory   = zeros(obj.options.numTrials, obj.options.nu);
            
            % Perform numTrials random trials (each column of x is a trial)
            x                 = removeZeroModes(x, []);
            eNew                = rayleighQuotient(problem, x);
            e0                  = eNew;
            
            % Run a few relaxation sweeps
            for iteration = 1:obj.options.nu
                eOld        = eNew;
                
                % Relaxation sweep
                [x, r]    = iterativeMethod.run(x, r);
                x         = removeZeroModes(x, []);
                
                % Update statistics
                eNew        = rayleighQuotient(problem, x);
                reductionHistory(:, iteration) = eNew./eOld;
                cumulativeHistory(:, iteration) = eNew/e0;
            end
            
            % Average over trials
            wof = ((mean(cumulativeHistory, 1)).^(1./(1:obj.options.nu)))';
            stats = [];
        end
    end
end
