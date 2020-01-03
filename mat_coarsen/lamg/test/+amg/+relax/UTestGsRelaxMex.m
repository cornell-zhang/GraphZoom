classdef (Sealed) UTestGsRelaxMex < amg.AmgFixture
    %UTestGsRelaxMex Unit test of Gauss-Seidel MEX implementation.
    %   This class tests the gsrelax.c MEX function correctness.
    
    %=========================== PROPERTIES ==============================
    properties (Constant, GetAccess = protected)
        logger          = core.logging.Logger.getInstance('amg.relax.UTestGsRelaxMex')
    end
    
    %=========================== CONSTRUCTORS ============================
    methods
        function obj = UTestGsRelaxMex(name)
            %UTestGsRelaxMex Constructor
            %   UTestGsRelaxMex(name) constructs a test case using the
            %   specified name.
            obj = obj@amg.AmgFixture(name);
        end
    end
    
    %=========================== TESTING METHODS =========================
    methods
        function testMexCorrectness(obj)
            % Test that MEX code and slowermatlab code produce the same
            % result for a 1-D Laplacian problem.
            
            m = 250;        % Problem size
            p = 3;          % #RHSs
            nu = 5;     	% #sweeps
            
            g = Graphs.biharmonic([m m]);
            n = g.numNodes;
            A = g.laplacian;
            b = rand(n,p);
            x = 2*ones(n,p);
            r = b - A*x;
            
            % Run relaxation mex code
            tStart = tic;
            [yFast, rFast] = gsrelax(A,x,r,uint32(nu));
            tMex = toc(tStart);
            
            % Run relaxation m-code (slower but reliable)
            M = tril(A);
            N = A - M;
            tStart = tic;
            [y, r] = amg.relax.UTestGsRelaxMex.gsrelax_matlab(A,M,N,b,x,r,nu);
            tMatlab = toc(tStart);
            
            assertTrue(norm(y-yFast)/norm(y) < 1e-15);
            assertTrue(norm(r-rFast)/norm(r) < 1e-14);
            if (obj.logger.infoEnabled)
                obj.logger.info('Relaxation time: mex=%f sec, matlab=%f sec\n', ...
                    tMex, tMatlab);
            end
        end
    end
    
    %=========================== PRIVATE METHODS==========================
    methods (Static, Access = private)
        function [x, r] = gsrelax_matlab(A, M, N, b, x, dummy, nu) %#ok
            % Apply a relaxation sweep with an initial guess X to A*X=B
            % split into A=M+N. X can be a matrix whose columns are
            % multiple initial guesses. B is the corresponding RHS matrix.
            for i = 1:nu
                x = M\(b - N*x);
            end
            r = b - A*x;
        end
    end
end
