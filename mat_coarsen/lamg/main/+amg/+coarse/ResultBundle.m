classdef (Sealed, Hidden) ResultBundle < handle
    %RESULTBUNDLE Aggregation experiment set - result
    %place-holder.
    %   This class holds statistics on different aggregations that can be
    %   compared to determine the optimal one among them.
    %
    %   See also: AGGREGATORHCR.
    
    %======================== PROPERTIES ==============================
    %     properties (GetAccess = public, SetAccess = public)
    %         coarseSet           % Final coarse set
    %     end
    properties (GetAccess = public, SetAccess = private)
        parameter           % Primary continuation parameter (coarsening stage/nu)
        alpha               % Coarsening ratio
        work                % Estimated multi-level cycle work
        acf                 % HCR ACF
        beta                % HCR ACF per unit work
        T                   % Coarse type operator
        aggregateIndex      % An optional map of i -> I (for caliber-1 T's only)
        nu                  % Number of relaxations per HCR sweep
        %x                   % Asymptotic HCR error vector
        %normR               % Normalized residuals of x (L2 norm)
        numExperiments = 0  % Keeps track of #experiments stored in this object
        %level               % Used to compute normalized residuals
        cycleIndex          % Design cycle index
        level               % Fine level problem
    end
    
    %======================== CONSTRUCTORS ============================
    methods
        function obj = ResultBundle(level, cycleIndex)
            % A factory method of an empty result struct for design cycle
            % index CYCLEINDEX that will store the accumulated results of
            % all coarsening stages/nu-tests.
            obj.level       = level;
            obj.cycleIndex  = cycleIndex;
        end
    end
    
    %======================== METHODS =================================
    methods
        function addResult(obj, parameter, T, aggregateIndex, nu, acf, b, dummy) %#ok
            % Add the result of a single coarsening experimen to this
            % object. Input: PARAMETER = primary experiment's parameter
            % value; T = coarse type operator; NU = #relaxation sweeps per
            % HCR sweep; ACF = HCR asymptotic convergence factor; x = HCR
            % asymptotic error vector.
            
            % Compute statistics
            a       = (1.0*size(T,1))/size(T,2);        % Coarsening ratio
            w       = nu/max(0, 1-obj.cycleIndex*a);    % Estimated multi-level cycle work. Infinite for a >= 1/gamma.

            % Store in a new entry
            obj.numExperiments      = obj.numExperiments+1;
            index                   = obj.numExperiments;
            obj.parameter(index)    = parameter;
            obj.acf(index)          = acf;
            obj.alpha(index)        = a;
            obj.work(index)         = w;
            obj.beta(index)         = b;
            obj.nu(index)           = nu;
            obj.T{index}            = T;
            obj.aggregateIndex{index} = aggregateIndex;
            %obj.x{index}            = x;
            %obj.normR(index)        = lpnorm(obj.level.normalizedResiduals(x))/lpnorm(x);
        end
        
        function [index, T, aggregateIndex, beta, nu, acf] = optimalResult(obj)
            % Return the index of the minimum BETA (highest efficiency)
            % among the experiments stored in this object. Also returns the
            % optimal BETA and the corresponding type operator T and
            % asymtotic vector x.
            
            [beta, index]   = min(obj.beta);
            aggregateIndex  = obj.aggregateIndex{index};
            T               = obj.T{index};
            nu              = obj.nu(index);
            acf             = obj.acf(index);
            %x               = obj.x{index};
        end
        
        function result = betaIncreased(obj, s, betaIncreaseTol)
            % Purpose: decide whether beta increased too much over the
            % coarsening stages s, s-1 with respect to its global minimum
            % so far. Input:
            %     beta - array of HCR beta values. s - stage number
            %     betaIncreaseTol - beta increase tolerance
            % Output: a flag indicating whether beta increased too much.
            S = s-1:s;
            S(S <= 0) = [];
            change = amg.coarse.ResultBundle.relativeChange(obj.beta, S);
            result = min(change) >= betaIncreaseTol;
        end
        
        function plot(obj, xAxis)
            % Create a plot of this object.
            clf;
            hold on;
            switch (xAxis)
                case 'alpha',
                    opt = obj.optimalResult();
                    
                    %                     % Plot a smooth spline through
                    %                     points cs = spline(obj.alpha, [0
                    %                     obj.beta 0.1]); xx =
                    %                     linspace(min(obj.alpha),
                    %                     max(obj.alpha), 101); yy =
                    %                     ppval(cs,xx); plot(xx, yy, 'b-',
                    %                     'LineWidth', 2);
                    plot(obj.alpha, obj.beta, 'b-', 'LineWidth', 2);
                    plot(obj.alpha, obj.beta, 'r.', 'MarkerSize', 30);
                    plot(obj.alpha(opt), obj.beta(opt), 'g.', 'MarkerSize', 30);
                    xlabel('\alpha [Coarsening Ratio]');
                    ylabel('\beta [HCR ACF Per Unit Work]');
                    title('HCR Efficiency Optimization: Phase 1');
                case 'nu',
                    [Nu, i] = sort(obj.nu);
                    Beta = obj.beta(i);
                    %NormR = obj.normR(i);
                    [dummy, opt] = min(Beta); %#ok
                    
                    plot(Nu, Beta, 'b-', 'LineWidth', 2);
                    plot(Nu, Beta, 'r.', 'MarkerSize', 30);
                    plot(Nu(opt), Beta(opt), 'g.', 'MarkerSize', 30);
                    %                    plot(Nu, NormR, 'g.-',
                    %                    'MarkerSize', 30);
                    xlabel('\nu [# Sweeps Per Cycle]');
                    title('HCR Efficiency Optimization: Phase 2');
                    ylabel('\beta [HCR ACF Per Unit Work]');
                    ylim([0 1]);
                otherwise,
                    error('Unrecognized x-axis parameter %s', xAxis);
            end
            shg;
        end
    end
    
    %======================== PRIVATE METHODS =========================
    methods (Static, Access = public)
        function change = relativeChange(beta, s)
            % Purpose: compute the relative change in beta at coarsening
            % stage s. Input:
            %     beta - array of HCR beta values. s - stage number
            % Output: relative change in beta at stage  s.
            %            if (~isempty(find(s < 2, 1)))
            %                error('Cannot compute a relative change for
            %                less than 2 sweeps');
            %            else
            
            change = (1-min(beta))./(1-beta(s));
        end
    end
    
    methods (Access = private)
    end
end
