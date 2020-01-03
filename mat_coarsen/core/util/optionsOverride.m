function result = optionsOverride(default_options, options)
%OPTIONSOVERRIDE Override a default options struct with custom options.
%   RESULT = OPTIONSOVERRIDE(DEFAULT_OPTIONS, OPTIONS) returns a struct
%   that contains DEFAULT_OPTIONS fields, unless they also exist in
%   OPTIONS, in which case they are overriden with the latter's value.
%
%   See also STRUCT.

%==========================================================================

if (nargin ~= 2)
    error('MATLAB:OPTIONS_OVERRIDE:InputArg','Must pass 2 arguments');
end

result = default_options;
fields = fieldnames(options);
for i = 1:numel(fields)
    field = fields{i};
    result.(field) = options.(field);
end
