function ginterp(action)
%GINTERP  Display interpolating function through given points
%
%  Call simply as ginterp with no arguments.
%
%  Usage is pretty self-explanatory, and help is available.
%
% author: Douglas N. Arnold, 9/96, 10/96

% This routine establishes a bunch of callbacks which are all
% to ginterp(action) for different actions.  A lot of variables
% have to be declared global to be shared by the different calls.

global ginterpfig ginterpaxes
global xminbox xmaxbox yminbox ymaxbox xmin xmax ymin ymax
global helpfig helpfigup morehelpfig morehelpfigup n x y nplot gridbutton extrapbutton
global typepopup interptype xpmin xpmax extrapolate loadbox loadfile

if nargin == 0,
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  initialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % start new figure
  ginterpfig = figure(...
    'Position',[100 400 560 420],...
    'Name',[interptype ' interpolation'],...
    'NumberTitle','off',...
    'DefaultUicontrolFontSize',12);
  ginterpaxes = axes(...,
    'Position',[.1 .2 .8 .7],...
    'Units','normalized',...
    'Box','on',...
    'Color','black',...
    'XColor',[.5 .5 .5],...
    'YColor',[.5 .5 .5],...
    'GridLineStyle','-',...
    'XLim',[-1 1],...
    'YLim',[-1 1],...
    'XLimMode','manual',...
    'YLimMode','manual',...
    'XGrid','on',...
    'YGrid','on',...
    'DefaultLineLineWidth',2);
  interptype = 'polynomial';
  % set up control widgets
  % plot limits
  frame = uicontrol(ginterpfig,...
    'Style','frame',...
    'Position',[5 7 350 27]);
  xminprompt = uicontrol(ginterpfig,...
    'Style','text',...
    'String','xmin:',...
    'Position',[10 10 40 20]);
  xminbox = uicontrol(ginterpfig,...
    'Style','edit',...
    'String','-1.0',...
    'Position',[50 10 40 20],...
    'CallBack','ginterp(''setxmin'')');
  xmaxprompt = uicontrol(ginterpfig,...
    'Style','text',...
    'String','xmax:',...
    'Position',[95 10 40 20]);
  xmaxbox = uicontrol(ginterpfig,...
    'Style','edit',...
    'String',' 1.0',...
    'Position',[135 10 40 20],...
    'CallBack','ginterp(''setxmax'')');
  yminprompt = uicontrol(ginterpfig,...
    'Style','text',...
    'String','ymin:',...
    'Position',[180 10 40 20]);
  yminbox = uicontrol(ginterpfig,...
    'Style','edit',...
    'String','-1.0',...
    'Position',[220 10 40 20],...
    'CallBack','ginterp(''setymin'')');
  ymaxprompt = uicontrol(ginterpfig,...
    'Style','text',...
    'String','ymax:',...
    'Position',[265 10 40 20]);
  ymaxbox = uicontrol(ginterpfig,...
    'Style','edit',...
    'String',' 1.0',...
    'Position',[305 10 40 20],...
    'CallBack','ginterp(''setymax'')');
  
  %  "Interpolate", "Reset", "Help", and "Quit" buttons
  ibutton = uicontrol(ginterpfig,...
     'Style','push',...
     'String','Interpolate',...
    'Position',[10 40 80 20],...
     'CallBack','ginterp(''interpolate'')',...
     'BackgroundColor',[0 0 .8],'ForegroundColor','yellow');
  rbutton  = uicontrol(ginterpfig,...
     'Style','push',...
     'String','Reset',...
    'Position',[95 40 80 20],...
     'BackgroundColor',[0 0 .8],'ForegroundColor','yellow',...
     'CallBack','ginterp(''reset'')'); 
  hbutton = uicontrol(ginterpfig,...
     'Style','push',...
     'String','Help',...
     'Position',[180 40 80 20],...
     'BackgroundColor',[0 0 .8],'ForegroundColor','yellow',...
     'CallBack','ginterp(''help'')');
  qbutton = uicontrol(ginterpfig,...
      'Style','push',...
      'String','Quit',...
      'Position',[265 40 80 20],... 
      'BackgroundColor',[0 0 .8],'ForegroundColor','yellow',...
      'CallBack','ginterp(''quit'')');
  lframe = uicontrol(ginterpfig,...
    'Style','frame',...
    'Position',[360 30 190 30]);
  loadprompt = uicontrol(ginterpfig,...
    'Style','text',...
    'String','load:',...
    'Position',[365 35 40 20]);
  loadbox = uicontrol(ginterpfig,...
    'Style','edit',...
    'Position',[405 35 120 20],...
    'HorizontalAlignment','left',...
    'CallBack','ginterp(''load'')');
  typepopup = uicontrol(ginterpfig,...
    'Style','popup',...
    'String','poly.|spline|pw lin.',...
    'Position',[360 7 70 20],...
    'CallBack','ginterp(''interptype'')');
  gridbutton = uicontrol(ginterpfig,...
    'Style','checkbox',...
    'String','grid',...
    'Position',[435 7 55 20],...
    'Value',1,...
    'CallBack','ginterp(''grid'')');
  extrapbutton = uicontrol(ginterpfig,...
    'Style','checkbox',...
    'String','extr.',...
    'Position',[495 7 55 20],...
    'CallBack','ginterp(''extrap'')');
    
  %  Set up mouse button to read and display input points
  set(ginterpfig,'WindowButtonDownfcn',['ginterp(''buttondown'');'])

  % initialize variables  
  xmin = -1;
  xmax = 1;
  ymin = -1;
  ymax = 1;
  n=0;
  x=[];
  y=[];
  nplot=500;
  helpfigup = 0;
  morehelpfigup = 0;
  extrapolate = 0;

elseif strcmp(action,'setxmin'),
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  setxmin callback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  xmin = str2num(get(xminbox,'String'));
  set(gca,'XLim',[xmin,xmax]);
elseif strcmp(action,'setxmax'),
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  setxmax callback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  xmax = str2num(get(xmaxbox,'String'));
  set(gca,'XLim',[xmin,xmax]);
elseif strcmp(action,'setymin'),
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  setymin callback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  ymin = str2num(get(yminbox,'String'));
  set(gca,'YLim',[ymin,ymax]);
elseif strcmp(action,'setymax'),
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  setymax callback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  ymax = str2num(get(ymaxbox,'String'));
  set(gca,'YLim',[ymin,ymax]);elseif strcmp(action,'setymax'),
elseif strcmp(action,'load'),
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  load callback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% When the load callback is called, the plot is reset and the data
% emptied.  Then a user-supplied file is read in as Matlab code.
% This file should define vectors x and y of interpolation points.
% These points are taken as the new data and plotted.  The file
% may also define some of xmin, xmax, ymin, and ymax, in which
% case these are set accordingly.
  loadfile = get(loadbox,'String');
  ginterp('reset')
  x=[]; y=[];
  eval(loadfile);
  set(xminbox,'String',num2str(xmin));
  set(xmaxbox,'String',num2str(xmax));
  set(yminbox,'String',num2str(ymin));
  set(ymaxbox,'String',num2str(ymax));
  set(gca,'XLim',[xmin,xmax]);
  set(gca,'YLim',[ymin,ymax]);
  n=min(length(x),length(y));
  x=x(1:n); y=y(1:n);
  for j=1:n
    line(x(j),y(j),'Marker','.','MarkerSize',25,'Color','red',...
      'erasemode','background');
  end
elseif strcmp(action,'interpolate'),
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  interpolate callback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  if n == 0
    disp('You must first supply points to interpolate.')
  else
    if extrapolate
      xpmin = xmin;
      xpmax = xmax;
    else
      xpmin = min(x(1:n));
      xpmax = max(x(1:n));
    end
    if (interptype(1:6) == 'polyno')
      % compute the interpolating polynomial using Newton's form:
      %  compute divided difference table
      d = y;
      for i = 1:n-1
        for j=n:-1:i+1
          d(j) = (d(j) - d(j-1)) / (x(j) - x(j-i));
        end
      end
      %  evaluate polynomial
      t = linspace(xpmin,xpmax,nplot);
      v = d(n)*ones(size(t));
      for i = n-1:-1:1
        v = v.*(t-x(i)) + d(i);
      end
      %  and plot it
      line(t,v,'erasemode','background','color','yellow');
    elseif (interptype(1:6) == 'spline')
      % interpolate a single point with a constant
      if n == 1
        line([xpmin,xpmax],[y(1),y(1)],'erasemode','background','color','green');
      else
      % evaluate spline interpolant using Matlab supplied spline.m
        t = linspace(xpmin,xpmax,nplot);
        line(t,spline(x,y,t),'erasemode','background','color','green');
      end
    elseif (interptype(1:6) == 'piecew')
      % interpolate a single point with a constant
      if n == 1
        line([xpmin,xpmax],[y(1),y(1)],'erasemode','background','color','cyan');
      else
      % sort points by increasing x coordinate, add points at beginning and
      % end to handle extrapolation, and connect the points
        [x,i] = sort(x);
        y = y(i);
        xx = [xpmin,x,xpmax];
        yy = [y(1)+(xpmin-x(1))*(y(2)-y(1))/(x(2)-x(1)), y,...
              y(n)+(xpmax-x(n))*(y(n)-y(n-1))/(x(n)-x(n-1))];
        line(xx,yy,'erasemode','background','color','cyan');
      end
    end
  end
elseif strcmp(action,'reset'),
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  reset callback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  cla;
  n=0;
  x=[];
  y=[];
elseif strcmp(action,'help'),
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  help callback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  helpfig = figure('Position',[660,420,420,210],...
       'Name','Help','NumberTitle','off',...
       'DefaultUicontrolFontSize',12);
   
  % Define the help string to display.
  helpstr=[
  '                                                                '
  '                            ginterp.m by Douglas N. Arnold, 9/96'
  '                                                                '
  '    This tool demonstrates Lagrange interpolation and cubic     '
  '    spline interpolation of a given set of data points. Enter   '
  '    points by clicking the mouse within the axes box. When      '
  '    the desired number of points have been entered, click on    '
  '    the "Interpolate" button to display the interpolating       '
  '    polynomial.  The plot can be cleared by clicking on         '
  '    "Reset".  Click on the quit button to exit the program.     '
  ];
   
  % Display it.
  uicontrol(...
     'Style','edit',...
     'Units','normalized',...
     'BackGroundColor',[1 1 .9],...
     'ForeGroundColor',[.2 0 .6],...
     'String',helpstr,...
     'Position',[0 0 1 1],'Max',20,...
     'FontSize',12);
   
  % Button for more help.
  uicontrol(...
     'Style','push',...
     'String','More...',...
     'Position',[220 5 60 20],...
     'CallBack','ginterp(''morehelp'')')
   
elseif strcmp(action,'morehelp'),
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  morehelp callback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  morehelpfig = figure('Position',[660,420,420,350],...
       'Name','MoreHelp','NumberTitle','off',...
       'DefaultUicontrolFontSize',12);
   
  % Define the help string to display.
  morehelpstr=[
  '                                                                    '
  '    Use the "poly./spline/pw lin." popup to toggle between          '
  '    polynomial interpolation, cubic spline interpolation, and       '
  '    piecewise linear interpolation. (Not-a-knot end conditions      '
  '    are used for the cubic spline.) The plot limits can be          '
  '    changed at any time by typing into the boxes labelled           '
  '    xmin, xmax, ymin, and ymax. A grid can be toggled on            '
  '    and off with the button labelled "grid". Normally the           '
  '    interpolant is plotted between the first and last data          '
  '    points. It will instead be extended to the edges of the         '
  '    plotting box if the "extr." (extrapolate) toggle is on.         '
  '                                                                    '
  '    As an alternative to entering interpolation points with         '
  '    the mouse, you can create a Matlab M-file with commands         '
  '    defining vectors x and y of the same length. Typing the         '
  '    name of this file (without the .m suffix) will cause the        '
  '    file to be read and the interpolation points to be defined      '
  '    accordingly. The file may also define xmin, xmax, ymin,         '
  '    and/or ymax.                                                    '
  ];
   
  % Display it.
  uicontrol(...
     'Style','edit',...
     'Units','normalized',...
     'BackGroundColor',[1 1 .9],...
     'ForeGroundColor',[.2 0 .6],...
     'String',morehelpstr,...
     'Position',[0 0 1 1],'Max',20,...
     'FontSize',12);
   
elseif strcmp(action,'quit'),
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  quit callback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  delete(ginterpfig);
  return;
elseif strcmp(action,'grid'),
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  grid callback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  if get(gridbutton,'Value') == 1,
    set(ginterpaxes,'XGrid','on','YGrid','on');
  else
    set(ginterpaxes,'XGrid','off','YGrid','off');
  end
elseif strcmp(action,'extrap'),
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  extrap callback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  if get(extrapbutton,'Value') == 1,
    extrapolate=1;
  else
    extrapolate=0;
  end
elseif strcmp(action,'interptype'),
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  interptype callback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  if get(typepopup,'Value') == 1
    interptype = 'polynomial';
  elseif get(typepopup,'Value') == 2
    interptype = 'spline';
  else
    interptype = 'piecewise linear';
  end    
  set(ginterpfig,'Name',[interptype ' interpolation'])
elseif strcmp(action,'buttondown'),
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  ButtonDown function
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  pt=get(ginterpaxes,'CurrentPoint');
  if pt(1,1) >= xmin & pt(1,1) <= xmax & pt(1,2) >= ymin & pt(1,2) <= ymax
    line(pt(1,1),pt(1,2),'Marker','.','MarkerSize',25,...
      'Color','red','erasemode','background');
    n=n+1;
    x(n)=pt(1,1);
    y(n)=pt(1,2);
  end

end
