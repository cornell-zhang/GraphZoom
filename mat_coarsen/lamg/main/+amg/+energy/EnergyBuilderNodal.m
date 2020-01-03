classdef (Hidden, Sealed) EnergyBuilderNodal < amg.energy.EnergyBuilder
    %ENERGYBUILDERLSSUM Energy correction using local-term-sum
    %least-squares.
    %   This implementation builds a coarse-level energy as a sum of EI
    %   terms; each EI is fit (for TVs) in least-squares sense to the local
    %   sum of fine energy terms ei over each aggregate I.
    %
    %   See also: LEVEL, ENERGYBUILDER, ENERGYBUILDERFACTORY.
    
    %======================== IMPL: EnergyBuilder =====================
    properties (Constant, GetAccess = private)
        myLogger = core.logging.Logger.getInstance('amg.energy.EnergyBuilderNodal')
    end
    
    %======================== CONSTRUCTORS ============================
    methods
        function obj = EnergyBuilderNodal(fineLevel, coarseLevel, options)
            % Initialize a local-sum-LS energy correction.
            obj = obj@amg.energy.EnergyBuilder(fineLevel, coarseLevel, options);
        end
    end
    
    %======================== IMPL: EnergyBuilder =====================
    methods (Access = protected)
        function Ac = doBuildEnergy(obj)
            % Compute the energy-corrected coarse operator Bc using energy
            % interpolation of individual coarse terms (XI-XJ)^2 into fine
            % terms (xi-xj)^2. See
            % http://bamg.pbworks.com/w/page/32272849/Energy-Correction
            
            % Construct the coarse-level energy matrix
            nzList  = obj.buildCoarseEnergyNonZeroList();
            nc      = obj.coarseLevel.size;
            Ac      = sparse(nzList(:,1), nzList(:,2), nzList(:,3), nc, nc);
            if (obj.myLogger.debugEnabled)
                %disp(nzList); disp(Ac);
                obj.myLogger.debug('Negative coarse weights list:\n');
                [i,j]= find(Ac<0);
                disp(full([i j Ac(Ac < 0)]));
            end
            
            % Convert energy weight matrix to a Laplacian operator
            Ac      = 0.5*(Ac+Ac');
            Ac      = diag(sum(Ac,1)) - Ac;
        end
    end
    
    %======================== PRIVATE METHODS =========================
    methods (Access = private)
        function nzList = buildCoarseEnergyNonZeroList(obj)
            % Create a non-zero list of coarse energy term coefficients
            % that is later used form the the new Ac. Useful aliases - fine
            % level
            
            A                   = obj.fineLevel.A;
            n                   = obj.fineLevel.size;
            x                   = obj.fineLevel.x;
            r                   = A*x;
            Efine               = obj.coarseLevel.restrict(x.*r - 0.5*(A*x.^2));
            rRestricted         = obj.coarseLevel.restrict(r);
            
            % Useful aliases - coarse level
            xc                  = obj.coarseLevel.T * x;
            Ac                  = diag(diag(obj.coarseLevel.A)) - obj.coarseLevel.A; % Ac without the diagonal
            nc                  = obj.coarseLevel.size;
            numEdgesCoarse      = obj.coarseLevel.g.numEdges;
            % LS weights
            lambda              = obj.options.energyResidualFactor;
            % sum_j |aij| over all j's in nodal energy of i
            nodalEnergyTotal    = obj.coarseLevel.restrict(abs(A - diag(diag(A))) * ones(n,1));
            % sum(aij (xi-xj)^2)/sum|aij| = fine energy per link
            globalEnergy        = obj.tvEnergyFine();
            W = spdiags(obj.fineLevel.g.weight, 0, obj.fineLevel.g.numEdges, obj.fineLevel.g.numEdges);
            globalEnergyPerLink = max(2*globalEnergy, eps)' ./ full(sum(abs(W(:))));
            
            wEnergy             = sqrt(1-lambda)./(nodalEnergyTotal * globalEnergyPerLink);
            wResidual           = sqrt(lambda);
            %wResidual           = sqrt(lambda)./abs(rRestricted);
            
            %wEnergy             = sqrt(1-lambda)./Efine; wResidual =
            %repmat(sqrt(lambda), nc, 1);
            
            % Solve weighted LS problems one by one. For each (i,j), find
            % the best fit among neighboring (I,J). Append the solution
            % into a non-zero list that is later used form the the new Ac.
            %numEdges        = coarseLevel.g.numEdges;
            % Initial allocation; doubled as needed later
            nzList  = zeros(numEdgesCoarse, 3);
            nzSize  = 0;                            % Keeps track of nzList's row size
            fit     = zeros(nc, 1);                 % Records goodness-of-fit to all fine edges
            sz      = round(numEdgesCoarse/20);
            for I = 1:nc
                if ((mod(I,sz) == 0) && (obj.myLogger.debugEnabled))
                    obj.myLogger.debug('%3.f%% Completed.\n', (100.*I)/nc);
                end
                
                % Prepare and solve LS problem
                [coef, fit(I)] = obj.fitCoarseEquation(I, ...
                    Efine(I,:), rRestricted(I,:), ...
                    wEnergy(I,:), wResidual(I,:), ...
                    Ac, xc, lambda);
                
                % Add interpolation weights of coarse energy terms into the
                % overall non-zero list. Multiple occurrences of the same
                % term in the list lead to incrementing the corresponding
                % sparse matrix entry, which is the desired behavior.
                numTerms                        = size(coef, 1);
                newNzSize                       = nzSize+numTerms;
                nzList(nzSize+1:newNzSize,:)    = coef;
                nzSize                          = newNzSize;
            end
            
            % Truncate over-allocated empty entries. Save results in fields
            obj.fit = fit;
        end
        
        function [interpolation, fit] = fitCoarseEquation(obj, ...
                I, Efine, rRestricted, wEnergy, wResidual, Ac, xc, dummy) %#ok
            % Fit an interpolation of neighboring EKL's to an eij term.
            % Returns a non-zero list INTERPOLATION in the format
            % (K,L,alpha(K,L)) where alpha is the interpolation coefficient
            % from coarse edge (K,L) to fine edge (i,j), and the
            % goodness-of-fit measure FIT.
            
            % Identify neigboring coarse nodes
            [J, AIJ] = find(Ac(:,I)); %#ok
            
            % Set up LS problem
            sz      = numel(J);
            dx      = repmat(xc(I,:), sz, 1)-xc(J,:);  % XI - XJ
            
            % Compute and display affinities between eij and {EKL}_{K,L}
            if (obj.options.energyFitDebug)
                %                 obj.printf('Coarse node I=%d at
                %                 (%d,%d)\n', I, ...
                %                     obj.coarseLevel.g.metadata.attributes
                %                     .subscript{1}(I,:), ...
                %                     obj.coarseLevel.g.metadata.attributes
                %                     .subscript{2}(I,:));
                obj.printf('Coarse node I=%d\n', I);
                obj.printf('Associate nodes:\n');
                [dummy, i] = find(obj.coarseLevel.R(I,:)); %#ok
                clear dummy;
                if (isfield(obj.fineLevel.g.metadata.attributes, 'subscript'))
                    obj.printf('  i=%d (%d,%d)\n', ...
                        [i; ...
                        obj.fineLevel.g.metadata.attributes.subscript{1}(i)'; ...
                        obj.fineLevel.g.metadata.attributes.subscript{2}(i)']);
                end
            end
            
            % Regularization term: minimum deviation from Galerkin
            %             target          = [(wEnergy.*Efine)'; wResidual *
            %             AIJ]; regressors      = [...
            %                 0.5 * repmat(wEnergy, sz, 1) .* dx.^2 ...
            %                 wResidual * eye(P)]';
            %             b = regressors\target;
            
            % Fit coarse equation using ridge regression
            target          = [wEnergy.*Efine wResidual.*rRestricted]';
            regressors      = [...
                0.5 * repmat(wEnergy, sz, 1) .* dx.^2 ...
                repmat(wResidual, sz, 1) .* dx]';
            
            % Adaptive regularization parameter to balance energy, residual
            % terms
            %K = numel(wEnergy); lambda = 0.1*mean(target(1:K)) ./
            %target(K+1:2*K); b = [regressors(1:K,:);
            %diag(lambda)*regressors(K+1:2*K,:)]\[target(1:K);
            %lambda.*target(K+1:2*K)];
            
            P = numel(J);
            done = false;
            in = 1:P;
            minCoef = 0; %-Inf; %0;%-0.1;
            while ~done
                b               = regressors(:,in)\target;
                
                %             ratio = 3; b(abs(b - ratio) < .1) = ratio;
                %             b(abs(b - 1/ratio) < .1) = 1/ratio;
                fit             = sqrt(sum((target - regressors(:,in)*b).^2)/numel(target));
                
                if (obj.options.energyFitDebug)
                    obj.printf('\nInterp.fit = %.3e\n', fit);
                    obj.printf('Columns included:');
                    obj.printf( ' %d', J(in));
                    obj.printf( ' [');
                    obj.printf( ' %.3g', b);
                    obj.printf( ' ] in =');
                    obj.printf( ' %d', in);
                    obj.printf('\n');
                end
                done = isempty(find(b < minCoef, 1));
                in(b < minCoef) = [];
            end
            
            % Final output of this method
            interpolation   = [repmat(I, numel(in), 1) J(in) b];
            if (obj.options.energyFitDebug)
                obj.printf('================================================================\n');
            end
            
            % Allow breakpoint at a certain edge, for debugging
            if (obj.myLogger.debugEnabled && (I == obj.options.energyDebugEdgeIndex))
                obj.myLogger.debug('Debugging a specific coarse node I = %d\n', I);
                disp([regressors target]);
                disp(regressors\target);
                obj.plotEnergyInterpolation(I, J, b, in);
                aaa=0; %#ok
            end
        end
        
        function plotEnergyInterpolation(obj, I, J, b, in)
            % Plot fine fine and coarse terms selected for its
            % interpolation.
            
            % Useful quantities
            T = obj.coarseLevel.g.coord([I; J],:);
            II = repmat(I, size(J));
            Tedge = 0.5*(obj.coarseLevel.g.coord(II,:) + obj.coarseLevel.g.coord(J,:));
            
            [dummy, fineNbhrs] = find(obj.coarseLevel.R([I; J],:)); %#ok
            clear dummy;
            t = obj.fineLevel.g.coord(fineNbhrs,:);
            %tv = obj.fineLevel.g.coord([i j],:);
            
            limits = [min(min(T),min(t)) max(max(T),max(t))];
            alpha   = 1.2; % Padding factor
            limits = [ ...
                0.5*(1+alpha)*limits(1) + 0.5*(1-alpha)*limits(3), ...
                0.5*(1-alpha)*limits(1) + 0.5*(1+alpha)*limits(3), ...
                0.5*(1+alpha)*limits(2) + 0.5*(1-alpha)*limits(4), ...
                0.5*(1-alpha)*limits(2) + 0.5*(1+alpha)*limits(4) ...
                ];
            %unit = [limits(2)-limits(1) limits(4)-limits(3)];
            
            figure(300);
            clf;
            hold on;
            
            % Set image axis
            set(gcf, 'Units' , 'Normalized');
            set(gcf, 'Position', [0.2 0.2 0.65 0.65]);
            axis equal;
            axis(limits);
            
            % Coarse term edges
            h = line([obj.coarseLevel.g.coord(II,1) obj.coarseLevel.g.coord(J,1)]', ...
                [obj.coarseLevel.g.coord(II,2) obj.coarseLevel.g.coord(J,2)]', ...
                'Color', 'r', 'LineWidth', 3);
            uistack(h, 'bottom');
            
            % Coarse nodes
            plot(T(:,1), T(:,2), 'ro', 'MarkerSize', 25, 'MarkerFaceColor', 'white');
            %uistack(h, 'top');
            
            % Coarse node labels
            label = [I;J];
            strings = cellfun(@(x)(sprintf('%d', x)), mat2cell(label, ones(size(label))), 'UniformOutput', false);
            text(T(:,1), T(:,2), strings, 'HorizontalAlignment', 'center', 'color', 'r');
            %uistack(h, 'top');
            
            % Coarse equation coefficients
            label = b;
            % Coarse edge mid-points
            strings = cellfun(@(x)(sprintf('%.2g', x)), mat2cell(label, ones(size(label))), 'UniformOutput', false);
            h = text(Tedge(in,1), Tedge(in,2), strings, 'HorizontalAlignment', 'center', 'color', 'k');
            uistack(h, 'top');
            
            % Fine nodes
            plot(t(:,1), t(:,2), 'ko', 'MarkerSize', 20, 'MarkerFaceColor', 'white');
            
            % Fine term
            %             h = line(tv(:,1), tv(:,2), 'Color', 'k',
            %             'LineWidth', 3); uistack(h, 'bottom');
            
            % Fine node labels
            label = fineNbhrs;
            strings = cellfun(@(x)(sprintf('%d', x)), mat2cell(label, ones(size(label))), 'UniformOutput', false);
            h = text(t(:,1), t(:,2), strings, 'HorizontalAlignment', 'center', 'color', 'k');
            uistack(h, 'top');
            
            shg;
        end
    end
end
