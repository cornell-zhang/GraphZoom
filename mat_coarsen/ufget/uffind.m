function id = uffind(field, varargin)
%UFFIND Find UF Collection instances.
%   ID = UFFIND(FIELD, VARARGIN) returns the list of IDs matching the
%   search criteria. FIELD is the field name to search on. VARARGIN
%   contains the list of values to match. Currently supported fields are
%
%       ID = UFFIND('kind', KEYWORD1, ..., KEYWORDN) returns all problem
%       IDs whose kind string contains all of the keywords KEYWORD1, ...,
%       KEYWORDN.
%
%       See also: UFGET, UFKINDS.

kinds = ufkinds;

switch (field)
    case 'kind',
        id = find(cellfun(@(k)(strfindall(k, varargin{:})), kinds));
    otherwise
        error('MATLAB:uffind:InputArg', 'Unsupported search field ''%s''', field);
end

end
