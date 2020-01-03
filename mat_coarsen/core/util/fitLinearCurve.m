function [yFit, p, fit] = fitLinearCurve(x, y, w, constantTerm)
%FITLINEARCURVE Fit a weighted LS regresion line.
%   [YFIT, P, FIT] = FITLINEARCURVE(X,Y) fits a regression line A*X+B to
%   the function Y(X). Y contains columns, each one is separately fitted to
%   x. YFIT is the interpolant, P = [A,B], and FIT is the normalized fit error.
%
%   See also: STEPWISEFIT.

if (size(x,1) == 1)
    x = x';
end
if (size(y,1) == 1)
    y = y';
end
if ((nargin <= 2) || isempty(w))
    w = ones(size(x));
end
if (nargin <= 3)
    constantTerm = true;
end
numCols = size(y,2);

% Fit y = a*x + b, p = [a_1..a_numVars b] or y = a*x
[numSamples, dummy]   = size(x); %#ok
W = diag(w.^2);
if (constantTerm)
    p                       = (W*[x ones(numSamples, 1)])\(W*y);
    % Evaluate the fit
    yFit                    = x*p(1:end-1,:) + repmat(p(end,:),[numSamples 1]);
else
    p                       = (W*x)\(W*y);
    % Evaluate the fit
    yFit                    = x*p;
end

% Compute goodness-of-fit
fit     = zeros(numCols, 1);
for i = 1:numCols
    fit(i) = norm(y(:,i)-yFit(:,i))/norm(y(:,i));
end

