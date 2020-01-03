function r = root(f,int,tol)
%
% ROOT(f,b,a,tol)
% hybrid secant/bisection method to find a root of f
%
% input:
%   f     string giving function (e.g., 'sin(x^3)+3*x-5')
%   int   vector of length two specifying a bracketing interval
%   tol   desired size of final bracketing interval
%         If tol is too small (e.g., tol=0), the smallest possible
%         interval (based on machine precision) will be found.
%         If tol is omitted, tol=0 is used.
%
% output:
%   r     approximate root
%
% This is a hybrid secant/bisection root-finding algorithm, intended for
% study.  Print statements are included to illustrate the progression
% of the algorithm.  Note: better (but more complicated) routines are
% available, e.g., Matlab's fzero.  This algorithm uses many of the
% same principles.
%
% Douglas N. Arnold, September 1997

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
fprintf('\n                eval                    x          f(x)\n');
fprintf(  '                ----    -----------------   -----------\n');
fprintf(  'input a            1   %18.16g %13.6g\n',a,fa);
fprintf(  'input b            2   %18.16g %13.6g\n',b,fb);

while 1 %%%%% START OF MAIN LOOP
    % There are three possible exits from this loop:
    %
    %    1) tolerance is achieved
    %    2) bracketing interval is as small as precision will allow
    %    3) exact root is found
    %
    % On entry to loop b is our current approximation, c is the previous b,
    % and a and b bracket the root.

    % If a is a better root than b, switch a and b, and let c be the
    % resulting a (b before the switch)
    if (abs(fb) > abs(fa))
      fprintf('switch a and b\n');
      temp = b; b = a; a = temp;
      temp = fb; fb = fa; fa = temp;
      c = a; fc = fa;
    end

    % check for convergence
    if (abs(a-b) <= tol)
      r = b;
      fprintf('\ntolerance achieved\n');
      fprintf('bracketing interval: %18.16g %18.16g\n',b,a);
      return
    end

    %   compute the increment for the bisection method based on a and b
    deltab = (a-b)/2;

    % if interval is as short as possible (can't distinguish midpoint from
    %  one of the endpoints), return
    if (b + deltab == b | b + deltab == a)
      r = b;
      if (tol > 0); fprintf('\ntolerance not achievable\n'); end
      fprintf('\nbracketing interval: %18.16g %18.16g\n',b,a);
      return
    end

    % compute the increment for the secant method based on b and c; use it
    % if it seems reasonable, else use bisection
    deltaf = fc - fb;
    if (deltaf == 0)
      % secant approximation impossible (division by zero), use bisection
      delta = deltab;
      fprintf('bisection\n');
    else
      % finish computation of secant increment
      deltas = -fb*(c-b)/deltaf;
      % secant method is deemed  reasonable if it moves the root b towards a,
      % but not too far (no more than half-way)
      if (sign(deltas) == sign(deltab) & abs(deltas) < abs(deltab))
        delta = deltas;
        fprintf('secant\n');
      else
        delta = deltab;
        fprintf('bisection\n');
      end
    end
    
    %   compute new approximation
    bnew = b + delta; fbnew = feval(f,bnew); count=count+1;

    % check for exact root
    if (fbnew == 0)
      r = bnew;
      fprintf('                %4d   %18.16g %13.6g\n',count,r,0);
      fprintf('\nexact root found\n');
      return
    end

    % update b and set c equal to old b
    c = b; b = bnew;
    fc = fb; fb = fbnew;

    % if the sign of f(b) changed, set a equal to the old b (now c) to
    % maintain a bracketing interval
    if (sign(fb) == sign(fa))
      a = c; fa = fc;
    end

    fprintf('                %4d   %18.16g %13.6g\n',count,b,fb);
end %%%%% END OF MAIN LOOP

