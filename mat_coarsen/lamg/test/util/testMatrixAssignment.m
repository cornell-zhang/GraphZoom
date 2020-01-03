function testMatrixAssignment
%testMatrixAssignment matrix assignment benchmark test.
%   Tests the speed of matrix assignment after a related slowness was
%   detected in CoarseSetMinEnergy.
%
%   See also: CoarseSetMinEnergy.

sz = 1e4;
n  = 1e5;

x = rand(sz,10);
y = rand(1,10);

t = tic;
k = 0;
for i = 1:n
    k = k+1;
    if (k > sz)
        k = 1;
    end
    x(k,:) = y;
end
fprintf('Time [inline]: %.2e sec/assignment\n', toc(t)/n);

t = tic;
k = 0;
for i = 1:n
    k = k+1;
    if (k > sz)
        k = 1;
    end
    x = assignRow(x, k, y);
end
fprintf('Time [func]  : %.2e sec/assignment\n', toc(t)/n);

a = Holder(10000,10);
t = tic;
k = 0;
for i = 1:n
    k = k+1;
    if (k > sz)
        k = 1;
    end
    a.assignRow(k, y);
end
fprintf('Time [class] : %.2e sec/assignment\n', toc(t)/n);

end

%--------------------------------------------------------------
function x = assignRow(x, i, y)
x(i,:) = y;
end
