classdef (Hidden) AbstractRelax < amg.relax.Relax
    %RELAX relaxation scheme.
    %   This is an interface for all damped relaxation methods of the type
    %
    %       M*X + N*XOLD = B XNEW = (1-w)*XOLD + w*X
    %
    %   to solve the level LEVEL problem A*X=B, where A=M+N is the method's
    %   splitting and omega is the damping parameter.
    
    %======================== MEMBERS =================================
    properties (GetAccess = private, SetAccess = private)
        omega               % Damping parameter
        damped              % Is omega != 1
        adaptive            % Run adaptive sweeps or not. For now these are GS sweeps.
        A                   % LHS Matrix
    end
    
    properties (GetAccess = public, SetAccess = private) % public get for 2-level operator debugging
        M                   % Cached "backward stencil" matrix
        N                   % Cached "forward stencil" matrix
        D                   % Distribution matrix (A = W*A*D)
    end
    
    %======================== CONSTRUCTORS ============================
    methods (Access = protected)
        function obj = AbstractRelax(level, W, D, omega, adaptive)
            % RELAX(LEVEL, OMEGA) initializes a relaxation scheme for the
            % level LEVEL problem with damping parameter OMEGA. If
            % homogeneous = true, relaxation is applied to A*x=0, otherwise
            % to A*x=b.
            obj             = obj@amg.relax.Relax(level);
            A               = level.A; %#ok
            if (~isempty(W))
                A           = W*A;  %#ok
            end
            if (~isempty(D))
                A           = A*D;  %#ok
                obj.D       = D;
            end
            obj.A           = A;    %#ok
            obj.M           = obj.getM(obj.A);
            obj.N           = obj.A - obj.M;
            obj.omega       = omega;
            obj.damped      = (abs(omega-1.0) > eps);
            obj.adaptive    = adaptive;
        end
    end
    
    %======================== IMPL: Relax =============================
    methods (Sealed)
        function [x, r] = runHomogeneous(obj, x, dummy1, nu) %#ok
            % Apply a relaxation sweep with an initial guess X to A*X=0. X
            % can be a matrix whose columns are multiple initial guesses.
            % Assuming X is an error vector, so the corresponding residual
            % is the action A*X.
            for i = 1:nu
                xold = x;
                x = -obj.M\(obj.N*xold);
                if (~isempty(obj.D))
                    x = obj.D * x;
                end
                if (obj.damped)
                    x = (1-obj.omega)*xold + obj.omega*x;
                end
            end
            % Explicitly calculates action (inefficient; could use dynamic
            % residual implementation instead)
            r = -obj.A*x;
        end
        
        function [xnew, rnew] = runWithRhs(obj, xold, dummy1, b, nu) %#ok
            % Apply a relaxation sweep with an initial guess X to A*X=B. X
            % can be a matrix whose columns are multiple initial guesses. B
            % is the corresponding RHS matrix.
            for i = 1:nu
                xnew = obj.M\(b - obj.N*xold);
                if (~isempty(obj.D))
                    xnew = obj.D * xnew;
                end
                if (obj.damped)
                    xnew = (1-obj.omega)*xold + obj.omega*xnew;
                end
            end
            % Explicitly calculates residual (inefficient; could use
            % dynamic residual implementation instead)
            rnew = b - obj.A*xnew;
        end
    end
    
    %======================== PRIVATE METHODS =========================
    methods (Abstract, Access = protected)
        M = getM(obj, A)
        % Compute the backward stencil matrix M of the relaxation scheme
        % for Ax=b.
    end
    
    methods (Access = protected)
        function x = adaptiveGsSweeps(obj, x, r)
            % Run adaptive GS sweeps on points with large residuals. Using
            % dynamic residuals instead of an M-N matrix form as it is
            % easier to implement in MATLAB.
            
            A       = obj.A; %#ok
            % Find outliers
            rAbs    = abs(r);
            local   = find(rAbs > 10*mean(rAbs));
            fprintf('Adaptive local sweeps\n');
            count = 0;
            while (~isempty(local))
                count = count+1;
                fprintf('Local sweep #%d   nodes = %d\n', count, numel(local));
                for i = local'
                    % GS step
                    delta   = r(i)/A(i,i); %#ok
                    x(i)    = x(i) + delta;
                    % Update dynamic residuals
                    ai      = A(:,i);%#ok
                    r       = r - delta*ai;
                end
                % Find outliers
                rAbs    = abs(r);
                local   = find(rAbs > 10*mean(rAbs));
            end
        end
    end
end
