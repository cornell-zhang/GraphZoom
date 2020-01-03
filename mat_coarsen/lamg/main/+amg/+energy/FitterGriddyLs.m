classdef (Hidden, Sealed) FitterGriddyLs < amg.energy.Fitter
    %GRIDDYFIT Fit a least-squares regression model using a griddy algorithm.
    %   B=GRIDDYFIT.FIT(X,Y) uses a griddy algorithm to best model the response
    %   variable Y as a function of the predictor variables represented by
    %   the columns of the matrix X.  The result B is a vector of estimated
    %   coefficient values for all columns of X.  GRIDDYFIT does NOT
    %   include a constant term (intercept) in the models.
    %
    %   GRIDDYFIT('PARAM1',val1,'PARAM2',val2,...) specifies one or
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
        function obj = FitterGriddyLs(varargin)
            %Construct a griddy regression model fitter.
            obj = obj@amg.energy.Fitter(varargin{:});
        end
    end
    
    %======================== IMPL: Fitter ============================
    methods
        function [b, in, fit] = fit(obj, allx, y)
            %   OBJ.FIT(X,Y) uses a griddy algorithm to best model the response
            %   variable Y as a function of the predictor variables
            %   represented by the columns of the matrix X.  The result B
            %   is a vector of estimated coefficient values for all columns
            %   of X.  GRIDDYFIT does NOT include a constant term
            %   (intercept) in the models.
            %
            %   [B,IN,FIT]=FIT(...) returns additional results. IN is a
            %   logical vector indicating which predictors are in the final model.
            %   FIT is the goodness-of-fit of the model.
            
            [K, P]                  = size(allx);
            opts                    = obj.options;
            opts.minCaliber         = max(1, opts.minCaliber);
            opts.maxCaliber         = min(P, opts.maxCaliber);
            ssrThreshold            = K*opts.fitThreshold^2;
            % Debugging printout output file
            f                       = opts.outputFile;
            if (isempty(f))
                f = 1; % Standard output
            end
            
            % Keeps track of the best fit found during the main loop
            best    = struct('ssResidual', Inf, 'in', [], 'b', [], 'final', false);
            
            %----------------------------------------------------
            % Griddy algorithm: scan predictor variables subsets of
            % increasingly larger size (caliber). The output caliber is
            % between minCaliber and maxCaliber.
            %----------------------------------------------------
            for caliber = 1:opts.maxCaliber
                if opts.display
                    fprintf(f, '*** caliber=%d\n', caliber);
                end
                % Loop over all combinations
                if (caliber == 1)
                    % Loop over all individual predictors; sort in
                    % ascending fit order for use for higher calibers
                    combinations = (1:P)';
                    % Save fits to construct a priority order of entering predictors into model for
                    % caliber>=2. Based on caliber=1 fitting results.
                    ssr = zeros(1,P);
                    order = (1:P); % Initial order
                else
                    % Build an array of all predictor combinations of size
                    % caliber. Sorted in lexicographic order
                    combinations = harmonics(caliber,P)+1;
                    combinations = combinations(min(diff(combinations,[],2),[],2) > 0,:);
                end
                
                % Scan combinations by priority order
                for i = 1:size(combinations,1)
                    in = order(combinations(i,:));
                    [b, ssResidual] = fitModel(obj, allx, y, in);
                    if (caliber == 1)
                        ssr(i) = ssResidual;
                    end
                    if opts.display
                        fprintf(f, '   fit=%8.3e  Columns included:', sqrt(ssResidual/K));
                        fprintf(f, ' %d', in);
                        fprintf(f, ' [');
                        fprintf(f, ' %.1g', b);
                        fprintf(f, ' ]\n');
                    end
                    if ((ssResidual < best.ssResidual) && (min(b) >= obj.options.minCoefficient))
                        % Found an admissible model that's the best to
                        % date, save it
                        best.ssResidual = ssResidual;
                        best.in         = in;
                        best.b          = b;
                        if (ssResidual < ssrThreshold)
                            % Model is good enough, stop
                            best.final = true;
                            break;
                        end
                    end
                end
                
                % Report results
                if opts.display
                    fprintf(f, '   Final model for caliber=%d   fit=%8.3e  Columns included:', numel(best.in), sqrt(best.ssResidual/K));
                    fprintf(f, ' %d', best.in);
                    fprintf(f, '\n');
                    fprintf(f, '    Column   Coefficient\n');
                    fprintf(f, '    [%2d]     [%10.5g]\n', [best.in; best.b']);
                end
                if (best.final)
                    % Found the final model, stop
                    break;
                end
                if (caliber == 1)
                    % Save priority order of entering predictors into model for
                    % caliber>=2. Based on caliber=1 fitting results.
                    [dummy, order] = sort(ssr, 'ascend'); %#ok
                    clear dummy;
                end
            end
            
            fit = sqrt(best.ssResidual/K);
            b   = best.b;
            in  = best.in;
        end
    end
    
    %======================== PRIVATE METHODS =========================
    methods (Access = private)
        function [b, ssResidual] = fitModel(obj, allx, y, in) %#ok<MANU>
            % Naively fit a model using the IN columns of ALLX to the
            % target Y. Returns the regression coefficients b of the IN
            % predictors and the sum of square residuals FIT.
            % TODO: use the faster QR factorization update here instead of mldivide!
            x           = allx(:,in);
            b           = x\y;
            ssResidual  = sum((y - x*b).^2);
        end
    end
end
