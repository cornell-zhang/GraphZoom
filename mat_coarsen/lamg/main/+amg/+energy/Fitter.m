classdef (Hidden) Fitter < amg.api.HasOptions
    %FITTER Fit regression model.
    %   B=FITTER.FIT(X,Y) uses a griddy algorithm to best model the response
    %   variable Y as a function of the predictor variables represented by
    %   the columns of the matrix X.  The result B is a vector of estimated
    %   coefficient values for all columns of X.  GRIDDYFIT does NOT
    %   include a constant term (intercept) in the models.
    %
    %   FITTER('PARAM1',val1,'PARAM2',val2,...) specifies one or
    %   more of the following name/value pairs:
    %
    %         'minCaliber'          Minimum number of predictors to include (default is 1)
    %         'maxCaliber'          Maximum number of predictors to include (default is none)
    %         'display'             display information about each step of not
    %         'outputFile'          The FID of a file to output display information to; (default standard output)
    %         'fitThreshold'        Stop and return model if fit gets below this threshold
    %         'minCoefficient'      Accept models whose coefficients are >= this value
    %         'ridgeParam'          Ridge regression regularization parameter (default 0)
    %
    %   See also: STEPWISEFIT, MLDIVIDE, QR.
    
    %=========================== CONSTRUCTORS ============================
    methods
        function obj = Fitter(varargin)
            %Construct a griddy regression model fitter.
            options = amg.energy.Fitter.parseArgs(varargin{:});
            obj = obj@amg.api.HasOptions(options);
        end
    end
    
    %======================== METHODS =================================
    methods (Abstract)
        [b, in, fit] = fit(obj, allx, y)
        %   OBJ.FIT(X,Y) uses a griddy algorithm to best model the response
        %   variable Y as a function of the predictor variables represented
        %   by the columns of the matrix X.  The result B is a vector of
        %   estimated coefficient values for all columns of X.  GRIDDYFIT
        %   does NOT include a constant term (intercept) in the models.
        %
        %   [B,IN,FIT]=FIT(...) returns additional results. IN is a logical
        %   vector indicating which predictors are in the final model. FIT
        %   is the goodness-of-fit of the model.
    end
    
    %======================== PRIVATE METHODS =========================
    methods (Static, Access = private)
        function options = parseArgs(varargin)
            % Parse options to the newInstance() method.
            p                   = inputParser;
            p.FunctionName      = 'Fitter';
            p.KeepUnmatched     = false;
            p.StructExpand      = true;
            
            %p.addRequired  ('method', @(x)(any(strcmp(x,{'griddy', 'stepwise'}))));
            p.addParamValue('minCaliber', 1, @isPositiveIntegral);
            p.addParamValue('maxCaliber', Inf, @isPositiveIntegral);
            p.addParamValue('display', true, @islogical);
            p.addParamValue('outputFile', 1, @isPositiveIntegral);
            p.addParamValue('fitThreshold', 0, @(x)(x >= 0));
            p.addParamValue('minCoefficient', -Inf, @isnumeric);
            
            p.parse(varargin{:});
            options = p.Results;
        end
    end
end
