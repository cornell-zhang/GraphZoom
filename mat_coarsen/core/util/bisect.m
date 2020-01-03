function r = bisect(f,int,tol)
%
% BISECT(f,a,b,tol)
% bisection method to find a root of f
%
% input:
%   f     string giving function (e.g., 'sin(x^3)+3*x-5')
%   int   vector of length two specifying a bracketing interval
%   tol   desired size of final bracketing interval
%         If tol is too small (e.g., tol=0), the smallest possible
%         interval (based on machine precision) will be found.
%         If tol is omitted, tol=0 is used.
%
%  output:
%    r   approximate root
%           r = (a'+b')/2 where f(a')*f(b') < 0 and abs(b' - a') < tol
%
% This is an implementation of the bisection root-finding algorithm.
% Print statements are included to illustrate the progression of the
% algorithm.

% check for 2 or 3 arguments, set tol=0 if not given
if (nargin == 2)
  tol = 0;
elseif (nargin ~= 3)
  fprintf('\nUsage: r = root(f,int,tol)\n');
  return
end

% interpret input function so it can be evaluated with feval
f=fcnchk(f);
% initialize a and b and evaluate function there, start with c=a
a=int(1); b=int(2); c=a;
fa = feval(f,a); fb = feval(f,b); fc = fa;
% initialize function evaluation counter
count = 2;

% check for exact root in input data
if (fa == 0)
  r = a; fprintf('\nexact root found:  %18.16g\n',r); return
end
if (fb == 0)
  r = b; fprintf('\nexact root found:  %18.16g\n',r); return
end

% make sure input interval brackets
if (sign(fa) == sign(fb))
  fprintf('\ninput interval does not bracket\n'); return
end

% display header and input data
fprintf('\neval                    x          f(x)\n');
fprintf(  '----    -----------------   -----------\n');
fprintf(  '   1   %18.16g %13.6g\n',a,fa);
fprintf(  '   2   %18.16g %13.6g\n',b,fb);

while 1 %%%%% START OF MAIN LOOP
  % check for convergence
    if (abs(a-b) <= tol)
      r = b;
      fprintf('\ntolerance achieved\n');
      fprintf('bracketing interval: %18.16g %18.16g\n',b,a);
      return
    end

  % compute midpoint and evaluate function there
    c = (a +  b)/2; fc = feval(f,c);
    count = count+1;
    fprintf('%4d   %18.16g %13.6g\n',count,c,fc);

  % check if midpoint equals endpoint to machine precision;
  % if so stop, because we can't get a smaller interval
    if (c == a | c == b)
      r = c;
      fprintf('%4d   %18.16g %13.6g\n',count,b,fb);
      if (tol > 0); fprintf('\ntolerance not achievable\n'); end
      fprintf('\nbracketing interval: %18.16g %18.16g\n',b,a);
      return
      return
    end
    
  % replace bracketing interval with bracketing half interval
    if ( sign(fa) == sign(fc) )
      a = c;
      fa = fc;
    else
      b = c;
      fb = fc;
    end
end %%%%% END OF MAIN LOOP
