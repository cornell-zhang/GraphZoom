%SUITE_CORE Core project test suite.
%   MATLAB XUnit 2.0.1 does not yet support test suite directory scanning.
%   Therefore we manually add all tests here.

clear
runtests core.lang.LTestIndexing

runtests core.dlnode.UTestDlnode

runtests core.xunit.LTestXunit
runtests core.xunit.LTestXunit2
runtests core.xunit.subpackage.LTestXunit3
