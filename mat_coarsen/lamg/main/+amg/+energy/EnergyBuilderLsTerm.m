classdef (Hidden, Sealed) EnergyBuilderLsTerm < amg.energy.EnergyBuilder
    %ENERGYBUILDERLSSUM Energy correction using individual energy term
    %interpolation constructed via least-squares.
    %   This implementation builds each fine-level energy term separately
    %   by fitting an interpolation of neighboring coarse-level energy
    %   terms in least-squares sense to TVs. This is supposed to yield the
    %   most accurate energy correction.
    %
    %   See also: LEVEL, ENERGYBUILDER, ENERGYBUILDERFACTORY.
    
    %======================== IMPL: EnergyBuilder =====================
    properties (Constant, GetAccess = private)
        myLogger = core.logging.Logger.getInstance('amg.energy.EnergyBuilderLsTerm')
        FITTER_FACTORY = amg.energy.FitterFactory;
    end
    
    %======================== CONSTRUCTORS ============================
    methods
        function obj = EnergyBuilderLsTerm(fineLevel, coarseLevel, options)
            % Initialize a local-sum-LS energy correction.
            options.energyOutFile = [];
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
            Ac      = sparse(nzList(:,3), nzList(:,4), nzList(:,5), nc, nc);
            if (obj.options.energyFitDebug)
                disp(nzList);
                %disp(Ac);
                obj.printf('Negative coarse weights list:\n');
                disp(Ac(Ac < 0));
            end
            
            % Convert energy weight matrix to a Laplacian operator
            Ac      = Ac+Ac';
            Ac      = diag(sum(Ac,1)) - Ac;
        end
    end
    
    %======================== PRIVATE METHODS =========================
    methods (Access = private)
        function nzList = buildCoarseEnergyNonZeroList(obj)
            % Create a non-zero list of coarse energy term coefficients
            % that is later used form the the new Ac. Useful aliases - fine
            % level
            gFine           = obj.fineLevel.g;
            numEdgesFine    = gFine.numEdges;
            edgeFine        = gFine.edge;
            A               = obj.fineLevel.A;
            x               = obj.fineLevel.x;
            %eij             = (gFine.incidence * x).^2;             % Individual fine energy terms (xi-xj)^2
            eij             = (gFine.incidence * x);             % Individual fine energy terms (xi-xj)
            
            Efine           = obj.tvEnergyFine();
            % ls normalization factors = [global average energy per
            % link]^(-1)
            % http://bamg.pbworks.com/w/page/37086427/energy-interpolation-
            % algorithm
            %w               = full(sum(obj.fineLevel.g.weightMatrix(:)))./max(2*Efine(xfIndex), eps)';
            w               = sqrt(full(sum(obj.fineLevel.g.weightMatrix(:)))./max(2*Efine(xfIndex), eps)');
            % LS weights that account for local TV smoothing
            %tau             = 1./max(eps, sum(obj.fineLevel.normalizedResiduals(x).^2));
            %tau             = tau / sum(tau);
            %w               = w .* tau;
            
            % Useful aliases - coarse level
            xc                  = obj.coarseLevel.x;
            Ac                  = obj.coarseLevel.A;
            [aggregateIndex, dummy] = find(obj.coarseLevel.T); %#ok
            clear dummy;
            
            % Set fitting options
            fitter = amg.energy.EnergyBuilderLsTerm.FITTER_FACTORY.newInstance(...
                'griddy-ls', ...
                'maxCaliber', obj.options.energyCaliber, ...
                'fitThreshold',  obj.options.energyFitThreshold, ...
                'display', obj.options.energyFitDebug, ...
                'outputFile', obj.outFile, ...
                'minCoefficient', obj.options.energyMinWeight);

            % Solve weighted LS problems one by one. For each (i,j), find
            % the best fit among neighboring (I,J). Append the solution
            % into a non-zero list that is later used form the the new Ac.
            %numEdges        = coarseLevel.g.numEdges;
            % Initial allocation; doubled as needed later
            nzList  = zeros(2*numEdgesFine, 5);
            nzSize  = 0;                        % Keeps track of nzList's row size
            fit = zeros(numEdgesFine, 1);   % Records goodness-of-fit to all fine edges
            numInterpTerms = zeros(numEdgesFine, 1); % Records how many coarse terms are used per fine term
            sz = round(numEdgesFine/20);
            for v = 1:numEdgesFine
                if ((mod(v,sz) == 0) && (obj.myLogger.debugEnabled))
                    obj.myLogger.debug('%3.f%% Completed.\n', (100.*v)/numEdgesFine);
                end
                
                % Identify fine edges (i,j)
                [i,j] = deal(edgeFine(v,1),edgeFine(v,2));
                
                % Prepare and solve LS problem
                [interpolation, fit(v)] = obj.fitInterpolationToTerm(...
                    v, i, j, full(eij(v,:)), w, ...
                    Ac, xc, aggregateIndex, fitter);
                interpolation(:,5) = -A(i,j)*interpolation(:,5);
                
                % Add interpolation weights of coarse energy terms into the
                % overall non-zero list. Multiple occurrences of the same
                % term in the list lead to incrementing the corresponding
                % sparse matrix entry, which is the desired behavior.
                numTerms    = size(interpolation, 1);
                numInterpTerms(v) = numTerms;
                newNzSize   = nzSize+numTerms;
                % Double nz allocation if exceeding current allocation
                allocSize   = size(nzList,1);
                if (newNzSize > allocSize)
                    nzListOld   = nzList;
                    nzList      = zeros(2*allocSize, 3);
                    nzList(1:nzSize,:) = nzListOld(1:nzSize,:);
                end
                nzList(nzSize+1:newNzSize,:)    = interpolation;
                nzSize                          = newNzSize;
            end
            
            % Truncate over-allocated empty entries. Save results in fields
            nzList = nzList(1:nzSize,:);
            obj.fit = fit;
            obj.numInterpTerms = numInterpTerms;
        end
        
        function [interpolation, fit] = fitInterpolationToTerm(obj, ...
                v, i, j, eij, w, Ac, xc, aggregateIndex, fitter)
            % Fit an interpolation of neighboring EKL's to an eij term.
            % Returns a non-zero list INTERPOLATION in the format
            % (K,L,alpha(K,L)) where alpha is the interpolation coefficient
            % from coarse edge (K,L) to fine edge (i,j), and the
            % goodness-of-fit measure FIT.
            
            % Identify neigboring coarse nodes
            I                   = aggregateIndex([i j]);
            [coarseNbhrs, dummy]    = find(Ac(:,I)); %#ok
            clear dummy;
            coarseNbhrs         = unique(coarseNbhrs); % TODO: inline this for improved performance
            
            % Compute individual coarse energy terms = differences
            % (XK-XL)^2 for all coarse node edges (K,L)
            [Kindex, Lindex] = find(tril(Ac(coarseNbhrs,coarseNbhrs),-1));
            K           = coarseNbhrs(Kindex);
            L           = coarseNbhrs(Lindex);
            %EKL         = (xc(K,:)-xc(L,:)).^2;
            EKL         = (xc(K,:)-xc(L,:));
            numColumns  = size(EKL,1);
            
            % Compute and display affinities between eij and {EKL}_{K,L}
            if (obj.options.energyFitDebug)
                c  = affinity_l2(eij, EKL, w);
                obj.printf('Fine edge %d (i,j)=(%d,%d)\n', v,i,j);
                if (isequal(obj.fineLevel.g.metadata.attributes.dim, 2))
                    obj.printf('Between coordinates (%d,%d)--(%d,%d)\n', ...
                        obj.fineLevel.g.metadata.attributes.subscript{1}(i,:), ...
                        obj.fineLevel.g.metadata.attributes.subscript{2}(i,:), ...
                        obj.fineLevel.g.metadata.attributes.subscript{1}(j,:), ...
                        obj.fineLevel.g.metadata.attributes.subscript{2}(j,:) ...
                        );
                end
                obj.printf('   [#%-2d] Coarse edge (%d,%d)  c = %.3f\n', [(1:numColumns); K'; L'; c']);
            end
            
            % Fit interpolation using stepwise regression until fit is good
            % enough. Fit is relative to local fine energy.
            % Use ridge regression with a small lambda to induce stable
            % interpolation weights, hopefully positive too
            target          = (w .* eij)';
            regressors      = (repmat(w, numColumns, 1) .* EKL)';
            
            [dummy1, in, fit]    = fitter.fit(regressors, target); %#ok
            caliber = numel(in);
            if (obj.options.energyFitDebug)
                obj.printf('Fine edge %d (i,j)=(%d,%d)  interp.fit = %.3e  caliber = %d\n', v,i,j,fit,caliber);
%                obj.printf('================================================================\n');
            end
            
            % Now fit the quadratic difference term and regularize with
            % ridge regression
            target2         = target.^2;
            regressors2     = regressors(:,in).^2;
            lambda          = 0.25;
            target2         = [target2; zeros(caliber, 1)];
            regressors2     = [regressors2; sqrt(lambda)*eye(caliber)];
            b               = regressors2\target2;
            fit             = sqrt(sum((target2 - regressors2*b).^2)/numel(target2));
            
            if (obj.options.energyFitDebug)
                obj.printf('\nDiff^2:\nFine edge %d (i,j)=(%d,%d)  interp.fit = %.3e  caliber = %d\n', v,i,j,fit,caliber);
                obj.printf('Columns included:');
                obj.printf( ' %d', in);
                obj.printf( ' [');
                obj.printf( ' %.3g', b);
                obj.printf( ' ]\n');
                obj.printf('================================================================\n');
            end
            
            % Final output of this method
            interpolation   = [repmat([i j], caliber, 1) K(in) L(in) b];

            % Allow breakpoint at a certain edge, for debugging
            if (v == obj.options.energyDebugEdgeIndex)
                fprintf('Debugging a specific fine edge v = %d\n', v);
                disp([EKL' eij' w']);
                obj.plotEnergyInterpolation(i, j, K, L, b, in);
                %disp(regressors\target);
                aaa=0; %#ok
            end
        end
        
        function plotEnergyInterpolation(obj, i, j, K, L, b, in)
            % Plot fine fine and coarse terms selected for its
            % interpolation.
            
            % Useful quantities
            [dummy2, fineNbhrs] = find(obj.coarseLevel.R([K L],:)); %#ok
            t = obj.fineLevel.g.coord(fineNbhrs,:);
            tv = obj.fineLevel.g.coord([i j],:);
            Tedge = 0.5*(obj.coarseLevel.g.coord(K(in),:) + obj.coarseLevel.g.coord(L(in),:));
            T = obj.coarseLevel.g.coord([K L],:);
            
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
            
            % Coarse nodes
            plot(T(:,1), T(:,2), 'ro', 'MarkerSize', 25, 'MarkerFaceColor', 'white');
            
            % Coarse node labels
            label = [K;L];
            strings = cellfun(@(x)(sprintf('%d', x)), mat2cell(label, ones(size(label))), 'UniformOutput', false);
            text(T(:,1), T(:,2), strings, 'HorizontalAlignment', 'center', 'color', 'r');
            
            % Fine nodes
            plot(t(:,1), t(:,2), 'ko', 'MarkerSize', 20, 'MarkerFaceColor', 'white');
            
            % Fine term
            h = line(tv(:,1), tv(:,2), 'Color', 'k', 'LineWidth', 3);
            uistack(h, 'bottom');
            
            % Fine node labels
            label = [i;j];
            strings = cellfun(@(x)(sprintf('%d', x)), mat2cell(label, ones(size(label))), 'UniformOutput', false);
            h = text(tv(:,1), tv(:,2), strings, 'HorizontalAlignment', 'center', 'color', 'k');
            uistack(h, 'top');
            
            % Coarse terms in the interpolation stencil
            h = line([obj.coarseLevel.g.coord(K(in),1) obj.coarseLevel.g.coord(L(in),1)]', ...
                [obj.coarseLevel.g.coord(K(in),2) obj.coarseLevel.g.coord(L(in),2)]', ...
                'Color', 'r', 'LineWidth', 3);
            uistack(h, 'bottom');
            
            % Coarse terms in the interpolation stencil - interpolation coefficients
            label = b;
            % Coarse edge mid-points
            strings = cellfun(@(x)(sprintf('%.2g', x)), mat2cell(label, ones(size(label))), 'UniformOutput', false);
            h = text(Tedge(:,1), Tedge(:,2), strings, 'HorizontalAlignment', 'center', 'color', 'k');
            uistack(h, 'top');
            
            % Coarse terms not in the interpolation stencil
            out = setdiff(1:numel(K), ~in);
            h = line([obj.coarseLevel.g.coord(K(out),1) obj.coarseLevel.g.coord(L(out),1)]', ...
                [obj.coarseLevel.g.coord(K(out),2) obj.coarseLevel.g.coord(L(out),2)]', ...
                'Color', 'r', 'LineStyle', '--', 'LineWidth', 2);
            uistack(h, 'bottom');
            shg;
        end
    end
end
