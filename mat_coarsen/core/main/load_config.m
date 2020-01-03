function vars = load_config(fileName)
%LOAD_CONFIG Load global variables configuration from file.
%   GLOBAL_VARS = LOAD_CONFIG(FILENAME) loads the configuration from file
%   FILENAME.
%
%   The configuration file follows the Java properties format with
%   parameteric substitutions:
%
%       property1='dir'
%       property2=[property1 ''/subdir'']
%
%   Will load the struct GLOBAL_VARS containing property1='dir' and
%   property2='dir/subdir' as a global workspace variable.

% Read inputs
if (nargin ~= 1)
    error('MATLAB:load_config:InputArg', 'Must specify file name');
end

% Read file
fid = fopen(fileName);
data = textscan(fid, '%s%s', 'delimiter', '=');
fclose(fid);

vars = struct();
for i = 1:numel(data{1})
    propertyName = data{1}(i);
    propertyName = propertyName{1};
    propertyValue = data{2}(i);
    propertyValue = propertyValue{1};

    % Evaluate parametric substitutions
    eval(sprintf('%s = %s;', propertyName, propertyValue));
    % Store in the global struct
    eval(sprintf('vars.(''%s'') = %s;', propertyName, propertyValue));
end
