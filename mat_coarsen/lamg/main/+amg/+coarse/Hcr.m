classdef (Hidden, Sealed) Hcr < amg.api.IterativeMethod & amg.level.SingleLevelOperator
    %HCR Habituated compatible relaxation.
    %   This class runs an HCR(0,NU) sweep, i.e. a few Kaczmarz-Jacobi
    %   sweeps on the equation T*X=0, followed by NU relaxation sweeps on
    %   A*x=0. is a direct solver for non-overlapping aggregates. It is a
    %   decorator of the level's TV relaxation object.
    %
    %   See also: LEVEL, RELAX.
    
    %======================== MEMBERS =================================
    properties (GetAccess = private, SetAccess = private)
        nu                              % Relaxation sweeps per HCR sweep
        %muRhs                           % Kacmarz over-relaxation parameter
        numCompatibilitySweeps = 1      % # sweeps on T*x=0
    end
    
    %======================== MEMBERS =================================
    properties (GetAccess = private, SetAccess = private)
        T                               % Coarse set type matrix
        P % T^T
        D                               % Cached Kaczmarz distribution matrix
        M                               % Cached "backward stencil" matrix of Jacobi for T*D*y=0
    end
    
    %======================== CONSTRUCTORS ============================
    methods
        function obj = Hcr(level, T, nu, numCompatibilitySweeps)
            % HCR(LEVEL, T, NU) initializes an HCR scheme. Each HCR sweep
            % consists of NU LEVEL.tvRelax() sweeps, followed by
            % numCompatibilitySweeps Kaczmarz-Jacobi sweeps on T*x=0.
            
            if (nargin < 4)
                numCompatibilitySweeps = 1;
            end
            
            % Parameter settings
            obj                         = obj@amg.level.SingleLevelOperator(level);
            obj.nu                      = nu;
            %obj.muRhs                   = muRhs;
            obj.numCompatibilitySweeps  = numCompatibilitySweeps;
            
            % Cached matrices
            obj.T                       = T;
            obj.P = spones(T');
            obj.D                       = T';
            obj.M                       = diag(diag(T*obj.D));
        end
    end
    
    %======================== IMPL: IterativeMethod ===================
    methods (Sealed)
        function x = run(obj, x)
            % Apply an HCR(nu) sweep to X.
            
            % Compatibility sweeps on T*x=0
            for i = 1:obj.numCompatibilitySweeps
                %x = x - obj.muRhs * (obj.D * (obj.M \ (obj.T*x)));

                % Simulates energy discrepancy flat energy correction mu
                %                 y = obj.P * (obj.T * x);
                %                 A = obj.level.A;
                %                 E = x'*A*x;
                %                 Ec = y'*A*y;
                %                 mu = obj.muRhs * E/Ec;
                %                 fprintf('|x|=%.2e   E=%.2e   E/Ec=%.2f   mu=%.2f\n', ...
                %                     lpnorm(x), E, E/Ec, mu);
                %mu = 1/2;
                %mu = obj.muRhs;
                %                x = x - mu * obj.D * (obj.M \ (obj.T*x));

                x = x - obj.D * (obj.M \ (obj.T*x));
            end
            
            % nu relaxation sweeps on A*x=0
            x = obj.level.tvRelax(x, obj.nu);
        end
    end
    
    %======================== PRIVATE METHODs =========================
end
