classdef Builder < handle
    %BUILDER A builder of an object.
    %   This is a base interface for all classes that implement the Builder
    %   Pattern.
    %
    %   See also: RUNNERACF.
    
    %======================== METHODS =================================
    methods (Abstract)
        target = build(obj)
        % Return the target instance built by this builder class.
    end
end
