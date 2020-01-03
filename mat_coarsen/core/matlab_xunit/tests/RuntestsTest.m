%TestSuiteTest Unit tests for runtests command-line test runner.

classdef RuntestsTest < TestCaseInDir

   methods
       
       function self = RuntestsTest(name)
           self = self@TestCaseInDir(name, ...
               fullfile(fileparts(which(mfilename)), 'cwd_test'));
       end
      
      function test_noInputArgs(self)
          [T, did_pass] = evalc('runtests');
          % The cwd_test directory contains some test cases that fail,
          % so output of runtests should be false.
          assertFalse(did_pass);
      end
      
      function test_oneInputArg(self)
          [T, did_pass] = evalc('runtests(''testFoobar'')');
          % cwd_test/testFoobar.m is supposed to pass.
          assertTrue(did_pass);
      end
      
      function test_oneInputArgWithFilter_passing(self)
          [T, did_pass] = evalc('runtests(''TestCaseSubclass:testA'')');
          assertTrue(did_pass);
      end
      
      function test_oneInputArgWithFilter_failing(self)
          [T, did_pass] = evalc('runtests(''TestCaseSubclass:testB'')');
          assertFalse(did_pass);
      end
      
      function test_oneDirname(self)
          [T, did_pass] = evalc('runtests(''../dir1'')');
          assertTrue(did_pass);
          
          [T, did_pass] = evalc('runtests(''../dir2'')');
          assertFalse(did_pass);
      end
      
      function test_twoDirnames(self)
          [T, did_pass] = evalc('runtests(''../dir1'', ''../dir2'')');
          assertFalse(did_pass);
      end
      
      function test_optionStringsIgnored(self)
          % Option string at beginning.
          [T, did_pass] = evalc('runtests(''-bogus'', ''../dir1'')');
          assertTrue(did_pass);
          
          % Option string at end.
          [T, did_pass] = evalc('runtests(''../dir2'', ''-bogus'')');
          assertFalse(did_pass);
      end
      
   end

end