classdef Runnable < handle
    %RUNNABLE A runnable object.
    %   This interface runs some code in the run() method. It bears no
    %   relation to the RUNNER interface.
    
    %======================== METHODS =================================
    methods
        result = run(obj, attributes)
        % Run the main business code of this class. The ATTRIBUTES struct
        % contains additional meta data to customize this run.
    end
    
end
