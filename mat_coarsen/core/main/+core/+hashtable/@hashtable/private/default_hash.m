function k = default_hash(obj)
    if isscalar(obj)
        if isreal(obj)
            k = double(obj);
        elseif isnumeric(obj)
            k = conj(obj);
        elseif ischar(obj)
            k = double(uint16(obj));
        else
            k = 0.0;  % default, really lousy hash value
        end
    else
        % simple minded hash for matrices, etc: sum the first 10 elements
        % multiplied by some primes (to defeat symmetric arrays, for
        % instance).  Really big values could cause trouble here, though.
        N = prod(size(obj));
        M = min(N, 10);
        
        % identity and the first 9 primes
        p = double([1 2 3 5 7 11 13 17 19 23]);
        k = 0.0;
        for i = 1:M
            if iscell(obj)
                k = k + default_hash(obj{i}) * p(i);
            else
                k = k + default_hash(obj(i)) * p(i);
            end
        end
    end

        
