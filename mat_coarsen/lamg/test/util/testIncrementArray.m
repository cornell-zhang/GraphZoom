function  testIncrementArray()
%TESTINCREMENTARRAY Summary of this function goes here
%   Detailed explanation goes here

n = 1000000;
ntrials = 1000;
a = ones(n,1);
tic;
for ii=1:ntrials
    a = incr_first(a);
end
fprintf('Standard Matlab: %f seconds\n', toc);

end


%--------------------------------------------------------------
function a=incr_first(a)
% INCR_FIRST Increment the first entry in a matrix.
a(1) = a(1) + 1;
end
