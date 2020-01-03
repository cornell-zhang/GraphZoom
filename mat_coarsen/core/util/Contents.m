% Utilities for scientific computing.
% OREN MATLAB Toolbox   Version 6   28-Jun-2004
%
% Display and miscellaneous functions.
%   cellmatrix2matrix   - Convert a cell matrix to a matrix
%   D                   - Display a 2D array "as on a paper"
%   divide              - Integer division into almost-even parts
%   fac                 - Relative factors of a sequence of numbers
%   find_label          - Return the first instance of a string in a label arra
%   lpnorm              - Scaled Lp norm
%   lpnormcol           - Scaled Lp norm applied to columns
%   plot_func           - Surf-plot a 2D function, defined on a level (grid)
%   print_vector        - Print a vector.
%   quadroots           - Find roots of a quadratic polynomial using quadratic formula
%
% Index handling in multiple dimensions.
%   ball_list           - Create an index list for a d-dimensional ball
%   box_bin             - D-dimensional binary box - list of indices
%   box_efficiency      - Box efficiency of covering flagged cells
%   box_list            - Create an index list for a d-dimensional box
%   box_size            - Size of a box.
%   box_volume          - Volume of a box.
%   chec_range          - Check range of a d-dimensional index list
%   find_var            - 1D index of a d-D gridpoint in a lex ordered grid
%   ind2subm            - Multiple subscripts in matrix-form from linear index
%   ut                  - Unit vector
%
% Root-search methods.
%   bisect              - Bisection method
%   newton              - Newton's method to find a root of a function
%   root                - Hybrid secant/bisection root finding
%   secant              - Scalar nonlinear zero finding using the Secant method
%
% Interpolation operations.
%   chebpts             - Chebyshev points
%   eprod               - Evaluate the interpolation error product
%   ginterp             - Display interpolating function through given points
%   ninterp             - Evaluate Lagrange interpolating polynomial
%
% Numerical integration operations.
%   simpson             - Simpson's rule integration with equally spaced points
%   trapez              - Trapezoidal rule integration with equally spaced points
%
% Image operations.
%   cascade             - Dilate an image to a cascaded form
%   dilate              - Dilate a binary image
%   dilate_list         - Dilate a list of flagged cells
%
% Smooth functions.
%   smooth_cauchy       - Cauchy function
%   smooth_hump         - Infinitely differentiable finitely supported function
%   smooth_step         - Smooth step/transition function

% Author: Oren Livne
% Date  : 05/30/2004    Version 1
%                       Created basic files: lpnorm, secant, D, fac, ...
%         06/04/2004    Version 2
%                       Added dilate and cascade functions, added toolkit description
%         06/23/2004    Version 6
%                       Added dilate_list, smooth_* functions, print_vector
%         04/15/2010    Imported into SVN repository. Tracking versions
%                       there.
