function b = default_equals(x, y)
    if isscalar(x) && isscalar(y)
        if isnumeric(x) && isnumeric(y) || ischar(x) && ischar(y)
            b = x == y;
        elseif iscell(x) && iscell(y)
            b = default_equals(x{1}, y{1});
        elseif isobject(x) && isobject(y)
            if ismethod(x, 'eq')
                b = eq(x,y);
            else
                b = false;
            end
        elseif isstruct(x) && isstruct(y)
            f1 = sort(fieldnames(x));
            f2 = sort(fieldnames(y));
            if length(f1) == length(f2) && all(strcmp(f1, f2))
                b = true;
                for i = 1:length(f1)
                    if ~default_equals(getfield(x, f1{i}), getfield(y, f1{i}))
                        b = false;
                        break;
                    end
                end
            else
                b = false;
            end
        else
            % presumably different types, or something I don't support
            b = false;
        end
    else
        sz_x = prod(size(x));
        sz_y = prod(size(y));
        if sz_x == sz_y
            x = reshape(x, sz_x, 1);
            y = reshape(y, sz_y, 1);
            
            if isnumeric(x) && isnumeric(y) || ischar(x) && ischar(y)
                b = all(x == y);
            elseif iscell(x) && iscell(y)
                b = true;
                for i = 1:length(x)
                    if ~default_equals(x{i}, y{i})
                        b = false;
                        break;
                    end
                end
            else
                % ??? What other cases are there?
                b = false;
            end
        else
            b = false;
        end
    end
