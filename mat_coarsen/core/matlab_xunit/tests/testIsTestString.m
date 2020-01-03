function test_suite = testIsTestString
%testIsTestString Unit tests for isTestString

%   Steven L. Eddins
%   Copyright 2008 The MathWorks, Inc.

initTestSuite;

function testOneStringIs
assertTrue(xunit.utils.isTestString('testFoobar'));
assertTrue(xunit.utils.isTestString('Test_foobar'));

function testOneStringIsNot
assertFalse(xunit.utils.isTestString('foobar_test'));

function testCellArray
strs = {'testFoobar', 'foobar_test'};
assertEqual(xunit.utils.isTestString(strs), [true false]);
assertEqual(xunit.utils.isTestString(strs'), [true; false]);