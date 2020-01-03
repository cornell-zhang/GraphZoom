function print_vector(a, c, type)
%PRINT_VECTOR Print a vector.
%   PRINT_VECTOR(A,C,TYPE) prints the vector a in the format
%   "[ A(1) C A(2) C ... C A(LENGTH(A))]". C is a separation character.
%   If no C is specified, C = ''. TYPE is the type of variables in A:
%   TYPE = 'INT' or TYPE = 'FLOAT'. The default is 'INT'.
%   
%   See also EVAL, SPRINTF.

% Author: Oren Livne
%         06/17/2004    Version 1: Created

if (nargin < 2)
    c = '';
end
if (nargin < 3)
    type = 'int';
end

if (size(a,2) > 1)
    a = a';
end

switch (lower(type))
case 'int'
    f = '%4d';
case 'float'
    f = '%7.3f';
end

switch (lower(c))
case ''
    fprintf('[ ');
    eval(sprintf('fprintf(''%s '',a)',f));
    fprintf(']');
case 'x',
    fprintf('[ ');
    eval(sprintf('fprintf(''%s %c '',a(1:length(a)-1))',f,c));
    eval(sprintf('fprintf(''%s '',a(length(a)))',f));
    fprintf(']');
case ',',
    fprintf('[ ');
    eval(sprintf('fprintf(''%s%c'',a(1:length(a)-1))',f,c));
    eval(sprintf('fprintf(''%s '',a(length(a)))',f));
    fprintf(']');
end
