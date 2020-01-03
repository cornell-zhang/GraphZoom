classdef (Hidden, Sealed) RelaxElimination < amg.relax.Relax
    %RELAXELIMINATION Back-subsitution of an elimination level.
    %   This executes a "colored relaxation sub-sweep" that recovers the f
    %   nodes in terms of the c nodes by solving
    %
    %       A(F,F)*X(F) + A(F,C)*X(C) = B(F)
    %
    %   for X(F).
    %
    %   See also: RELAX.
    
    %======================== MEMBERS =================================
    properties (GetAccess = private, SetAccess = private)
        P                   % A(f,f)^{-1} A(f,c), cached
        q                   % A(f,f)^{-1}, cached
        f                   % F-nodes to be back-subsituted by this class
        c                   % C-nodes (coarse node set)
    end
    
    %======================== CONSTRUCTORS ============================
    methods
        function obj = RelaxElimination(level, f, c, stage)
            % RELAXELIMINATION(LEVEL, F, C) initializes an elimination
            % relaxation scheme for the level LEVEL problem where the node
            % set F is eliminated in terms of C. STAGE contains
            % elimination data structures.
            obj     = obj@amg.relax.Relax(level);
            obj.f   = f;
            obj.c   = c;
            obj.P   = stage.P;
            obj.q   = stage.q;
        end
    end
    
    %======================== IMPL: Relax =============================
    methods
        function runHomogeneous(obj, dummy1, dummy2) %#ok
            error('MATLAB:RelaxElimination:run', 'Unsupported operation');
        end
        
        function [x, r] = runWithRhs(obj, x, r, b, nu)
            % Back-susbtitute the F node values of x. Note: any positive nu
            % is ignored and treated like nu=1.
            %
            % Note: r is NOT updated here. Too expensive. Callers must
            % recompute r or avoid using it.
            if (nu > 0)
                %x(obj.f) = obj.Aff\(b(obj.f) - obj.Afc*x(obj.c));
                f = obj.f;                              %#ok
                x(f) = obj.P*x(obj.c) + obj.q.*b(f);    %#ok
            end
        end
        
        function run(obj, dummy1) %#ok
            error('MATLAB:RelaxElimination:run', 'Unsupported operation');
        end
    end
end
