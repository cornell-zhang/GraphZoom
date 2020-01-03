classdef (Sealed) hashtable
    % self = hashtable(['PropertyName', PropertyValue, ...])
    %
    % properties:
    %   'size'    - initial capacity of the hash table (default = 100)
    %
    %   'load'    - initial load factor (ratio of # contents / size
    %               above which the size will automatically be increased,
    %               default = 0.75)
    %
    %   'equals'  - the function (handle) to use for testing key equality.
    %               The default works for integers, reals, complex numbers,
    %               strings, matrices, structs, and cell arrays of the above,
    %               but of course may not be efficient or suitable for your
    %               particular data structure.  If you supply a new equality
    %               function, you should probably also supply a new hashcode
    %               function.  Equality functions should take two inputs and
    %               return a boolean.
    %
    %   'hash'    - the hashcode function to use to generate hash values
    %               for keys of the table.  The default works well only
    %               with numbers, strings, and matrices.
    %               Structs, cell arrays, etc. will get a very weak hash, so
    %               you'll need to supply a better hashcode function if you
    %               want to use these as keys.
    %
    %   'grow'    - factor by which to increase the size of the hashtable
    %               when needed (default = 1.5)
    %
    % Notes:
    %   The hashcode function is further enhanced by a simple internal hashing
    %   function which tries to help ensure even spreading over the available
    %   slots; however, no attempt has been made to provide a "perfect" hash.
    %
    %   The default equality function may or may not define equality in a way
    %   that you will like.  In general, if you use keys that are all of the
    %   same type, the equality function should distinguish keys that are
    %   differenself.  Numerical values are compared using ==, so double(1)
    %   "equals" int8(1).  Cell arrays and matrices are compared recursively,
    %   element by elemenself.  Structs are compared first by field names, then
    %   recursively by individual fields.  Objects (instances of a class) are
    %   compared if the method 'eq' is properly defined for the class,
    %   otherwise they are assumed non-equal.
    %
    properties (GetAccess = public, SetAccess = private)
        size
        numel
        load
        grow
        equals
        hash
        index
        entries
    end
    
    methods
        function self = hashtable(varargin)
            if nargin == 1
                if isa(varargin{1}, 'hashtable')
                    self = varargin{1};
                else
                    error('Unrecognized parameter list for hashtable constructor');
                end
            else
                initial_size = 100;
                load_factor = 0.75;
                eq_function = @default_equals;
                hash_function = @default_hash;
                growth_factor = 1.5;
                
                for i = 1:2:nargin
                    param = varargin{i};
                    val = varargin{i+1};
                    
                    switch param
                        case 'size'
                            initial_size = val;
                        case 'load'
                            load_factor = val;
                        case 'equals'
                            eq_function = val;
                        case 'hash'
                            hash_function = val;
                        case 'grow'
                            growth_factor = val;
                        otherwise
                            error('Unrecognized parameter for hashtable constructor');
                    end
                end
                
                self.size = initial_size;
                self.numel = 0;
                self.load = load_factor;
                self.grow = growth_factor;
                self.equals = eq_function;
                self.hash = hash_function;
                self.index = sparse(self.size, self.size);
                
                self.entries = cell(ceil(self.size * self.load), 1);
                
                %self = class(t, 'hashtable');
                
            end
        end
    end
end
