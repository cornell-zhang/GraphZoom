function out = runtestspackage(packageName, varargin)
%RUNTESTSPACKAGE Run all unit tests under a package.
%   runtestspackage runs all the test cases found in package packageName
% whose class name matches one of the regexp list varargin.
%
%   Examples:
%
%   Find and run all test cases (learning tests that start with 'LTest',
%   unit tests that start with 'UTest', and integration tests that start
%   with 'ITest') under the core.xunit package.
%
%       runtestspackage('core.xunit')
%
%   Find and run all the learning test cases, whose clsas name starts with
%   the string 'LTest' and return a pass/fail flag.
%
%       out = runtestspackage('core.xunit', 'LTest.*')

%   Oren E. Livne November 2009

import core.util.*;

if nargin < 2
    varargin{1} = 'LTest.*';
    varargin{2} = 'UTest.*';
    varargin{3} = 'ITest.*';
end
classes = findClasses(packageName, varargin{:});
out = true;
for k = 1:numel(classes)
    suite = TestSuite.fromName(classes{k});
    did_pass = suite.run(CommandWindowTestRunDisplay());
    if (~did_pass)
        out = false;
    end
end
