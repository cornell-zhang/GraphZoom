classdef (Sealed) UTestLamg < amg.AmgFixture
    %UTestLamg Unit test of the LAMG wrapper class.
    %   This class tests the runCycleAcf() function via the wrapper class
    %   Lamg.
    %
    %   See also: runCycleAcf.
    
    %=========================== PROPERTIES ==============================
    properties (Constant, GetAccess = protected)
        logger          = core.logging.Logger.getInstance('amg.solve.UTestLamg')
    end
    
    %=========================== CONSTRUCTORS ============================
    methods
        function obj = UTestLamg(name)
            %UTestLamg Constructor
            %   UTestLamg(name) constructs a test case using the
            %   specified name.
            obj = obj@amg.AmgFixture(name);
        end
    end
    
    %=========================== TESTING METHODS =========================
    methods
        function testGrid2d(obj) %#ok<MANU>
            % LAMG Example usage: a linear solve of a small 2-D grid.
            
            % Construct a solver
            lamg = Solvers.newSolver('lamg', 'errorNorm', @errorNormResidual, ...
                'errorReductionTol', 1e-8, 'logLevel', 1);
            
            % Create a graph adjacency matrix A. Note: g.laplacian is the corresponding
            % Laplacian matrix.
            g = Graphs.grid('fd', [20 20]);
            A = g.adjacency;
            
            % Setup phase: construct a LAMG multi-level hierarchy
            setup = lamg.setup('adjacency', A);
            
            % Solve phase: set up a compatible RHS b (remember: A is singular) and
            % solve A*x=b
            b = (1:size(A,1))';
            b = b - mean(b);
            [dummy1, success, dummy2, details] = lamg.solve(setup, b); %#ok
            
            assertTrue(success, 'LAMG failed');
            assertTrue(details.acf < 0.17, sprintf('2-D grid has to have ACF < 0.15 but was %.2f', details.acf));
        end
    end
    
    %=========================== PRIVATE METHODS =========================
end
