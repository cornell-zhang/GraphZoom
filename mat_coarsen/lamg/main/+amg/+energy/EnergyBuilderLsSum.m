classdef (Hidden, Sealed) EnergyBuilderLsSum < amg.energy.EnergyBuilder
    %ENERGYBUILDERLSSUM Energy correction using local-term-sum
    %least-squares.
    %   This implementation builds a coarse-level energy as a sum of EI
    %   terms; each EI is fit (for TVs) in least-squares sense to the local
    %   sum of fine energy terms ei over each aggregate I.
    %
    %   See also: LEVEL, ENERGYBUILDER, ENERGYBUILDERFACTORY.
    
    %======================== IMPL: EnergyBuilder =====================
    properties (Constant, GetAccess = private)
        myLogger = core.logging.Logger.getInstance('amg.energy.EnergyBuilderLsSum')
    end    
    
    %======================== CONSTRUCTORS ============================
    methods
        function obj = EnergyBuilderLsSum(fineLevel, coarseLevel)
            % Initialize a local-sum-LS energy correction.
           options.energyOutFile = [];
            obj = obj@amg.energy.EnergyBuilder(fineLevel, coarseLevel, options);
        end
    end
    
    %======================== IMPL: EnergyBuilder =====================
    methods (Access = protected)
        function Ac = doBuildEnergy(obj)
            % Return the corrected coarse-level operator Ac.
            w = obj.correctionVector();
            Ac = obj.correctionVectorToOperator(w, obj.coarseLevel.A);
            if (obj.myLogger.traceEnabled)
                figure(200);
                plot(obj.coarseLevel.g.coord, w, 'bx-');
                title('Coarse Energy Correction');
                xlabel('Node location t_I');
                ylabel('w_I');
                disp(w);
                %pause
            end
        end
    end
    
    %======================== PRIVATE METHODS =========================
    methods (Access = private)
        function w = correctionVector(obj)
            % Compute the energy correction explained in
            % http://bamg.pbworks.com/w/page/32272849/Energy-Correction
            
            % w_I is the solution of min[sum_k [w_I*a_I - b_I]^2 *
            % weight_k].
            X   = obj.fineLevel.x;
            A   = obj.fineLevel.A;
            b   = obj.coarseLevel.R * (X .* (A * X) - 0.5 * (A * X.^2));
            Y   = obj.coarseLevel.x;
            AC  = obj.coarseLevel.A;
            a   = Y .* (AC * Y) - 0.5 * (AC * Y.^2);
            % LS weights = 1/TV variances over aggregates. It's important
            % that variances are an averages over a neighborhood of
            % residuals, not point values that fluctuate and skew the LS
            %            w       = sum(d.*b, 2) ./ sum(d.*a, 2); weight  =
            %            b.^(-2);
            nc      = obj.coarseLevel.size;
            
            % Solve weighted LS problem
            bb      = b';
            aa      = a';
            for i = 1:nc
                ai = aa(:,i);
                if (max(abs(ai)) == 0)
                    % Rank deficient
                    w(i) = 1;
                else
                    w(i) = ai \ bb(:,i); % Much less round-off-sensitive than the explicit w = sum(d.*b, 2) ./ sum(d.*a, 2) if weights vary by orders of magnitude.
                end
            end
            % Goodness-of-fit
            %W   = spdiags(w, 0, nc, nc);
            %fit = sqrt(sum(((W*a - b)./b).^2, 2)/size(X,2));
            %fit = sqrt(sum((W*a - b).^2, 2)/size(X,2));
            %             if (obj.myLogger.debugEnabled)
            %                 disp([(1:obj.coarseLevel.size)' fit]);
            %                 %obj.coarseLevel.g.metadata.attributes.n
            %                 n=30;
            %                 figure(300);surf(reshape(fit,[n n/2])');title('Relative TV energy error');view(2);colorbar;shg
            %                 figure(301);surf(reshape(w,[n n/2])');title('w');view(2);colorbar;shg
            %             end
        end
        
        function Bc = correctionVectorToOperator(obj, w, Ac) %#ok<MANU>
            % Translate energy interpolation to new coarse operator
            nc      = size(Ac,1);
            W       = spdiags(w, 0, nc, nc);
            temp    = W*(Ac - diag(diag(Ac)));
            t       = 0.5*(temp+temp');
            Bc      = t - diag(sum(t,1));
        end
        
        function plotEnergies(obj, a, b, k)
            % Debugging plots of fine and coarse level energies
            tc  = obj.coarseLevel.g.coord;
            %t   = obj.fineLevel.g.coord;
            ac  = a(:,k);
            bc  = b(:,k);
            plot(tc, ac, 'r', tc, bc, 'b');
        end
    end
end
