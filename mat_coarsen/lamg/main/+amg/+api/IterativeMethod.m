classdef IterativeMethod < handle
    %ITERATIVEMETHOD An iterative method.
    %   This is a base interface for all iterative methods that tranform
    %   the current iterate to the next.
    %
    %   See also: RUNNERACF.
    
    %======================== METHODS =================================
    methods (Abstract)
        xnew = run(obj, xold)
        % XNEW = OBJ.RUN(XOLD,ITERANTHISTORY) executes the iterative method
        % on the current iterate XOLD , producing the next iterate, XNEW.
    end
end
