function [B, A] = testAugmentedSdd(input)
%TESTAUGMENTEDSDD Test augmenting an SDD system to make it an M-matrix.
%   [B,A]=TESTAUGMENTEDSDD(N) test funnction constructs an NxN biharmonic
%   graph Laplacian A and then constructs the augmented M-matrix system B =
%   [[D+N -P]; [-P D+N]], and tests if it is still SDD.
%
%   B=TESTAUGMENTEDSDD(A) accepts any matrix A instead of a size.
%
%   See also: GRAPHS.

% Create test example
if (nargin < 1)
    input = 5;
end
if (issparse(input))
    A = input;
else
    n = input;
    if (exist('Graphs', 'file') == 2)
        g = Graphs.biharmonic(n);
        A = g.laplacian;
    else
        % Hard-coded example with 5 nodes
        A =  biharmonicLaplacian();
    end
end

% Decompose A into its parts
D = diag(diag(A));
B = A-D;
P = B;
P(P < 0) = 0;
N = B;
N(N > 0) = 0;

% Construct the augmented system
B = [[D+N -P];[-P D+N]];

% Test for positive semi-definiteness
fprintf('A: ');
testPsd(A);
fprintf('B: ');
testPsd(B);

end

%-------------------------------------------------
function isSpd = testPsd(A)
% Test whether a matrix is positive semi-definite.
lminA = min(eig(A));
isSpd = lminA > -1e-15; % Allow round-off slack
if (isSpd)
    s = 'true';
else
    s = 'false';
end
fprintf('lambda_min = %e  SPD? %s\n', lminA, s);
end

%-------------------------------------------------
function A = biharmonicLaplacian()
% A fall-back to construct A if the LAMG library is not on the MATLAB path.
nzData = [ ...
    1     1     3; ...
    2     1    -4; ...
    3     1     1; ...
    1     2    -4; ...
    2     2     7; ...
    3     2    -4; ...
    4     2     1; ...
    1     3     1; ...
    2     3    -4; ...
    3     3     6; ...
    4     3    -4; ...
    5     3     1; ...
    2     4     1; ...
    3     4    -4; ...
    4     4     7; ...
    5     4    -4; ...
    3     5     1; ...
    4     5    -4; ...
    5     5     3; ...
    ];
A = spconvert(nzData);
end
