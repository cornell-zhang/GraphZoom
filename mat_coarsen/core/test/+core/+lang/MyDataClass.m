classdef MyDataClass
    %MYDATACLASS A simple class illustrating how to override indexing.
    %   See
    %   http://www.mathworks.com/access/helpdesk/help/techdoc/matlab_oop/br
    %   09eqz.html
    properties
        Data
        Description
    end
    properties (SetAccess = private)
        Date
    end
    methods
        function obj = MyDataClass(data,desc)
            if nargin > 0
                obj.Data = data;
            end
            if nargin > 1
                obj.Description = desc;
            end
            obj.Date = clock;
        end
        
        function sref = subsref(obj,s)
            % obj(i) is equivalent to obj.Data(i)
            switch s(1).type
                % Use the built-in subsref for dot notation
                case '.'
                    sref = builtin('subsref',obj,s);
                case '()'
                    if length(s)<2
                        % If the number of indexing levels is 1 (obj(2,3)
                        % has one level; not obj.Data(2,3) has two levels,
                        % obj.someProp(2,3).someNestedProp has three, etc.)
                        % delegate indexing to the Data array Note that
                        % obj.Data is passed to subsref
                        sref = builtin('subsref',obj.Data,s);
                        return
                    else
                        sref = builtin('subsref',obj,s);
                    end
                    % No support for indexing using '{}'
                case '{}'
                    error('MYDataClass:subsref',...
                        'Not a supported subscripted reference')
            end
        end
    end
end
