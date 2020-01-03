%SUITE_GMG Geometric Multigrid project test suite.
%   MATLAB XUnit 2.0.1 does not yet support test suite directory scanning.
%   Therefore we manually add all tests here.

% Run test suites
runtests graph.api.UTestGraph
runtests graph.reader.UTestBatchReader
runtests graph.writer.UTestWriter
runtests graph.runner.UTestBatchRunner
runtests graph.runner.UTestPump
runtests graph.printer.UTestPrinter
runtests graph.plotter.UTestGraphPlotter
