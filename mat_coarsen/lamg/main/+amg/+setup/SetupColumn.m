classdef (Enumeration, Hidden, Sealed) SetupColumn < int8
    %SETUPCOLUMN Metadata column of a Setup object.
    %   This is an enumeration of SETUP info matrix columns.
    %
    %   See also: SETUP, SETUPBUILDER.
    
    %======================== CONSTANTS ===============================
    enumeration
        STATE               (1)  % Level type = coarsening strategy
        NODES               (2)  % # level nodes
        EDGES               (3)  % # level edges
        NU                  (4)  % Total number of relaxations to perform
        NU_PRE              (5)  % # pre-CGC relaxations to perform
        NU_POST             (6)  % # post-CGC relaxations to perform
        CYCLE_INDEX         (7)  % Cycle index at all levels
        NUM_TV              (8)  % # test vectors at all levels
        P_COMPLEXITY        (9)  % Interpolation operator complexity per coarse-level node
        RELAX_COMPLEXITY    (10) % Relaxation sweep complexity per node
        DEGREE_L2           (11) % L2 average node degree
        TIME_COARSENING     (12) % Time-per-edge of P, R and Galerkin operator computation at this level
        TIME_RELAX          (13) % Time-per-edge of all relaxations performed at this level (relax speed check and TVs)
        TIME_OTHER          (14) % Rest of setup time-per-edge at this level
%        HCR                 (2)  % HCR ACF
%        BETA                (3)  % HCR ACF per unit work
%        NUM_COMPONENTS      (5)  % # graph connected components
    end
    
    %======================== METHODS =================================
    methods (Static)
        function n = numColumns()
            % Return the number of columns.
            n = numel(enumeration('amg.setup.SetupColumn'));
        end
    end
end
