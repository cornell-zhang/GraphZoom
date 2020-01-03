classdef Indexable < handle
    %INDEXABLE An abstract of classes that can be accessed via subscript
    %notation (e.g. an array). Allows to reuse the SUBSREF and SUBSASGN
    %template implementations using object call-backs for the inner code
    %that depends on the object's details.
    
    %=========================== PROPERTIES ==============================
    
    %=========================== CONSTRUCTORS ============================
    
    %=========================== METHODS: CALLBACKS ======================
    
    methods (Abstract)
        % obj(s) reference call-back
        sref = indexRef(obj, s)
        
        % obj(s) = val assignment call-back
        obj = indexAssign(obj, s, val)
    end
    
    %=========================== METHODS: INDEXING =======================
    methods
        function sref = subsref(obj, s)
            % obj(i) is equivalent to obj.data(i-1), so that our grid
            % indexing is zero-based.
            switch s(1).type
                % Use the built-in subsref for dot notation
                case '.'
                    sref = builtin('subsref', obj, s);
                case '()'
                    if length(s)<2
                        % obj(s) reference call-back
                        sref = indexRef(obj, s);
                        return
                    else
                        sref = builtin('subsref', obj, s);
                    end
                    % No support for indexing using '{}'
                case '{}'
                    error('%s:subsref',...
                        'Not a supported subscripted reference', class(obj))
            end
        end
        
        function obj = subsasgn(obj,s,val)
            % Index assignment: obj(s)=val.
            clazz = class(obj);
            if isempty(s) && strcmp(class(val),clazz)
                obj = MyDataClass(val.Data,val.Description);
            end
            switch s(1).type
                % Use the built-in subsasagn for dot notation
                case '.'
                    obj = builtin('subsasgn', obj, s, val);
                case '()'
                    if length(s)<2
                        if strcmp(class(val),clazz)
                            error('%s:subsasgn: ',...
                                'Object must be scalar', clazz)
                        elseif strcmp(class(val),'double')
                            % obj(s) = val assignment call-back
                            obj = indexAssign(obj, s, val);
                        end
                    end
                    % No support for indexing using '{}'
                case '{}'
                    error('%s:subsasgn: ',...
                        clazz,'Not a supported subscripted assignment')
            end
        end
    end
end
