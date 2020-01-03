function [yFit, p, fit] = fit_linear_curve(x, y, n, xTitles, yTitle, nTitle, constantTerm)
%FIT_LINEAR_CURVE Fit a line to functions for various values of n.
%   y contains columns, each one is linearly fit to x.

if (nargin <= 6)
    constantTerm = true;
end
if (size(x,1) == 1)
    x = x';
end
if (size(y,1) == 1)
    y = y';
end
numCols = size(y,2);
printResults = (nargin >= 3);

if (printResults && ~iscell(xTitles))
    xTitle = xTitles;
    xTitles = cell(numCols, 1);
    for i = 1:numCols
        xTitles{i} = xTitle;
    end
end
    
% Fit y = a*x + b, p = [a_1..a_numVars b] or y = a*x
[numSamples, numVars]   = size(x);
if (constantTerm)
    p                       = [x ones(numSamples, 1)]\y;
    % Evaluate the fit
    yFit                    = x*p(1:end-1,:) + repmat(p(end,:),[numSamples 1]);
else
    p                       = x\y;
    % Evaluate the fit
    yFit                    = x*p;
end

% Compute goodness-of-fit
fit     = zeros(numCols, 1);
for i = 1:numCols
    fit(i) = norm(y(:,i)-yFit(:,i))/norm(y(:,i));
end

% Print results
if (printResults)
for i = 1:numCols
    if (~isempty(n))
        fprintf('%s = %4d: ', nTitle, n(i));
    end
    fprintf('%s ~', yTitle);
    fprintf(' %s %s', sprintf('%.3e', p(1,i)), xTitles{1});
    for j = 2:numVars
        fprintf(' %s %s', signedPrint('%.3e', p(j,i)), xTitles{j});
    end
    if (constantTerm)
        fprintf(' %s', signedPrint('%.3e', p(end,i)));
    end
    fprintf('   fit = %.3e\n', fit(i));
end
%fprintf('\n');
end

%----------------------------------------------------------
function s = signedPrint(format, x)
s = sprintf(sprintf('%%s %s', format), signString(x), abs(x));

%----------------------------------------------------------
function sign = signString(x)
if (x >= 0)
    sign = '+';
else
    sign = '-';
end
