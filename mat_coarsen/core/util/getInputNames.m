function name_list = getInputNames(varargin)
%GETINPUTNAMES Convert varargin to a list of strings.
%   LIST = GETINPUTNAMES(VARAGIN) returns a cell array of strings from
%   VARARGIN. If it encounters an empty argument, a warning is printed and
%   the argument is not added to LIST.
name_list = {};
for k = 1:numel(varargin)
    name = varargin{k};
    if isempty(name)
        warning('getInputNames:unrecognizedOption', 'Unrecognized option: %s', name);
    else
        name_list{end+1} = name;
    end
end
