function [tAdd, tMvm, tMvmx, tRelax] = testRelaxTime(setup)
%testRelaxTime Test relaxation time vs. number of edges within a setup
%hierarchy.
%   This test function computes matrix-vector-multiplication and relaxation
%   speed for each level in a LAMG setup hierarchy.
%
%   See also: SETUP.

nu      = 4;
K       = 4;

L       = setup.numLevels;
tAdd    = zeros(L,1);
tMvm    = zeros(L,1);
tMvmx   = zeros(L,1);
tRelax  = zeros(L,1);
for l = 1:L,
    A = setup.level{l}.A;
    n = setup.level{l}.g.numNodes; 
    m = setup.level{l}.g.numEdges; 
    b = ones(n,K);
    x = rand(n,K); 
    
    start       = tic; 
    y           = x+b; %#ok
    tAdd(l) 	= toc(start)/(n*K);

    %B = A(1,:);    
    start       = tic; 
    y           = A*x; %#ok %B*x; %#ok
    tMvm(l) 	= toc(start)/(m*K);

%     c = 1:floor(n/2);
%     f = floor(n/2)+1:n;
%     A1 = A(:,c)';
%     A2 = A(:,f)';
%     start       = tic; 
%     z           = [A1*x; A2*x]; %#ok
%     tMvmx(l)	= toc(start)/(m*K);

    start       = tic; 
    x           = gsrelax(A,b,x,uint32(nu)); %#ok
    tRelax(l) 	= toc(start)/(m*K*nu);
    
    fprintf('l=%2d   add=%.2e   mvm=%.2e   mtimesx=%.2e   relax=%.2e\n', ...
        l, tAdd(l), tMvm(l), tMvmx(l), tRelax(l));
end
end

% %------------------------------------------------------------------------
% function t = linearSolve(A)
% end
