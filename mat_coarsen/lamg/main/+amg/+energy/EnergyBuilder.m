classdef EnergyBuilder < amg.api.HasOptions
    %ENERGYBUILDER A coarse-level energy builder (energy correction).
    %   This is a base interface for all implementations of constructing a
    %   modified coarse-level energy using fine- and coarse-level TVs and
    %   an initial Galerkin coarse-level energy functional.
    %
    %   See also: LEVEL, ENERGYBUILDERFACTORY.
    
    %======================== PROPERTIES ==============================
    properties (Constant, GetAccess = private)
        logger = core.logging.Logger.getInstance('amg.energy.EnergyBuilder')
    end
    
    properties (GetAccess = public, SetAccess = protected)
        fit                 % Records goodness-of-fit to all fine edges
        numInterpTerms      % Records how many coarse terms are used per fine term
    end
    properties (Dependent)
        tvEnergyFine        % Fine-level energies of fine-level TVs
        tvEnergyCoarse      % coarse-level energies of coarse-level TVs
    end
    properties (GetAccess = protected, SetAccess = private)
        fineLevel           % Fine level
        coarseLevel         % Coarse level
        outFile             % Debugging printouts output file
    end
    
    %======================== CONSTRUCTORS ============================
    methods
        function obj = EnergyBuilder(fineLevel, coarseLevel, options)
            %Construct an energy builder of COARSELEVEL to fit FINELEVEL's
            %energy.
            if (isempty(options))
                options.energyOutFile = [];
            end
            obj = obj@amg.api.HasOptions(options);
            obj.fineLevel = fineLevel;
            obj.coarseLevel = coarseLevel;
        end
    end
    
    %======================== METHODS =================================
    methods (Sealed)
        function [Ac, mu] = buildEnergy(obj)
            % Return the modified coarse-level operator Ac corresponding to
            % the corrected coarse-level energy. This is done by fitting
            % coarse energy local terms to fine counterparts for TVs at
            % FINELEVEL and their COARSELEVEL restrictions.  [AC,MU] =
            % DOBUILDENERGY() also returns a RHS correction factor (either
            % scalar or vector) MU.
            global GLOBAL_VARS;
            if (~isempty(obj.options.energyOutFile))
                fileName = sprintf('%s/%s/%s/energy_builder_lev%d.txt', ...
                    GLOBAL_VARS.out_dir, obj.options.energyOutFile, ...
                    obj.fineLevel.g.metadata.name, obj.fineLevel.size);
                create_dir(fileName, 'file');
                obj.outFile = fopen(fileName, 'w');
            end
            Ac = obj.doBuildEnergy();
            if (nargout >= 2)
                mu = obj.doBuildRhsCorrection();
            end
            if (~isempty(obj.options.energyOutFile))
                fclose(obj.outFile);
            end
        end
        
        function printCurrentEnergies(obj)
            % Debugging printouts of fine and coarse level TV energies
            % currently held in this object.
            amg.energy.EnergyBuilder.printEnergies(obj.tvEnergyFine, obj.tvEnergyCoarse);
        end
    end
    
    methods
        function mu = adaptiveRhsCorrection(obj, x, xc) %#ok
            % Adaptive RHS correction, if this is an adaptive strategy. For
            % non-adaptive strategies, return an empty array.
            mu = [];
        end
    end
    
    %======================== GET & SET ===============================
    methods
        function Efine = get.tvEnergyFine(obj)
            % Return the fine-level energies of fine-level TVs.
            X       = obj.fineLevel.x;
            A       = obj.fineLevel.A;
            % Compute energy
            Efine   = sum(X.*(A*X), 1)';
        end
        
        function Ecoarse = get.tvEnergyCoarse(obj)
            % Return the coarse-level energies of coarse-level TVs.
            %Xc      = obj.coarseLevel.x;
            Xc      = obj.coarseLevel.T * obj.fineLevel.x;
            Ac      = obj.coarseLevel.A;
            % Compute energy
            Ecoarse = sum(Xc.*(Ac*Xc),1)';
        end
    end
    
    %======================== UTILITY METHODS =========================
    methods (Static)
        function printEnergies(Efine, Ecoarse)
            % Debugging printouts of fine and coarse level TV energies.
            fprintf('%-5s %-13s %-10s %-10s\n', 'TV', 'E(x)', 'Ec(Tx)', 'error');
            fprintf('-----------------------------------------\n');
            fprintf('#%2d   %.3e    %.3e (%.3f)\n', ...
                [(1:numel(Efine))', Efine, Ecoarse, abs(Efine-Ecoarse)./abs(Efine)]');
        end
    end
    
    %======================== PRIVATE METHODS =========================
    methods (Access = protected)
        function mu = doBuildRhsCorrection(obj) %#ok<MANU>
            % A hook for computing the RHS correction factor (scalar or
            % vector) mu.
            mu = []; % Indicates that RHS correction is to be ignored during cycle
        end
    end
    
    methods (Abstract, Access = protected)
        Ac = doBuildEnergy(obj)
        % Return the modified coarse-level operator Ac corresponding to the
        % corrected coarse-level energy. This is done by fitting coarse
        % energy local terms to fine counterparts for TVs at FINELEVEL and
        % their COARSELEVEL restrictions.
    end
    
    methods (Sealed, Access = protected)
        function printf(obj, varargin)
            % Print to output file if it is non-null.
            if (~isempty(obj.outFile))
                fprintf(obj.outFile, varargin{:});
                %             else
                %                 fprintf(varargin{:});
            end
        end
    end
end
