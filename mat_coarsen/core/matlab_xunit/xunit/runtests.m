function out = runtests(varargin)
%runtests Run unit tests
%   runtests runs all the test cases that can be found in the current directory
%   and summarizes the results in the Command Window.
%
%   Test cases can be found in the following places in the current directory:
%
%       * An M-file function whose name starts with "test" or "Test" that
%       returns no output arguments.
%
%       * An M-file function whose name starts with "test" or "Test" that
%       contains subfunction tests and uses the initTestSuite script to
%       return a TestSuite object.
%
%       * An M-file defining a subclass of TestCase.
%
%   runtests(dirname) runs all the test cases found in the specified directory.
%
%   runtests(mfilename) runs test cases found in the specified function or class
%   name. The function or class needs to be in the current directory or on the
%   MATLAB path.
%
%   runtests('mfilename:testname') runs the specific test case named 'testname'
%   found in the function or class 'name'.
%
%   Multiple directories or file names can be specified by passing multiple
%   names to runtests, as in runtests(name1, name2, ...). 
%
%   Examples
%   --------
%   Find and run all the test cases in the current directory.
%
%       runtests
%
%   Find and run all the test cases contained in the M-file myfunc.
%
%       runtests myfunc
%
%   Find and run all the test cases contained in the TestCase subclass
%   MyTestCase.
%
%       runtests MyTestCase
%
%   Run the test case named 'testFeature' contained in the M-file myfunc.
%
%       runtests myfunc:testFeature
%
%   Run all the tests in a specific directory.
%
%       runtests c:\Work\MyProject\tests
%
%   Run all the tests in two directories.
%
%       runtests c:\Work\MyProject\tests c:\Work\Book\tests

%   Steven L. Eddins
%   Copyright 2009 The MathWorks, Inc.

if nargin < 1
    suite = TestSuite.fromPwd();
else
    name_list = getInputNames(varargin{:});
    if numel(name_list) == 1
        suite = TestSuite.fromName(name_list{1});
    else
        suite = TestSuite();
        for k = 1:numel(name_list)
            suite.add(TestSuite.fromName(name_list{k}));
        end
    end
end

did_pass = suite.run(CommandWindowTestRunDisplay());

if nargout > 0
    out = did_pass;
end

function name_list = getInputNames(varargin)
name_list = {};
for k = 1:numel(varargin)
    name = varargin{k};
    if ~isempty(name) && (name(1) == '-')
        warning('runtests:unrecognizedOption', 'Unrecognized option: %s', name);
    else
        name_list{end+1} = name;
    end
end
