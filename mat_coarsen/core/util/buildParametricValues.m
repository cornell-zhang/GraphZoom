function p = buildParametricValues(varargin)
%BUILD_PARAMETRIC_VALUES Generate a matrix of values for parametric
%   P = BUILD_PARAMETRIC_VALUES(VARARGIN) for a list of vectors VARARGIN =
%   V1,...,VP returns a matrix of size P x LENGTH(V1) x ...x LENGTH(VP)
%   that is similar to the output of NDGRID. If each Vi is a parameter in a
%   parametric study, P contains the N-vector values of the V's for every
%   possible experiment, sorted lexicographically.
%
%   See also: NDGRID.

%==========================================================================

% Use ndgrid to get p as a cell array first
num_parameters = length(varargin);
pcell = cell(num_parameters, 1);
[pcell{:}] = ndgrid(varargin{:});
num_experiments = length(pcell{1}(:));

% Convert the cell array to a matrix
p = zeros(num_experiments, num_parameters);
for i = 1:num_parameters
    temp = pcell{i}';
    p(:,i) = temp(:);
end
