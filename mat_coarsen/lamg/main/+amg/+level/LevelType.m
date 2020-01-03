classdef (Enumeration, Sealed) LevelType < int8
    %COARSENINGTYPE Level type.
    %   This is an enumeration of level types. Note: this is not exactly
    %   isomorphic to coarsening staates.
    %
    %   See also: LEVEL, COARSENINGSTATE, MULTILEVELSETUP.
    
    %======================== CONSTANTS ===============================
    enumeration
        FINEST(0)               % Finest level
        ELIMINATION(1)          % Eliminate 0-, 1-, 2- degree and other low-impact nodes
        AGG(2)                 % AGG coarsening level (caliber-1 P + Galerkin + energy correction)
    end
end
