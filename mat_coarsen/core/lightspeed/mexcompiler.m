function [compiler,libloc,vsinstalldir,vcvarsopts] = mexcompiler
% mexcompiler returns the name of the compiler used by mex.

% Written by Tom Minka

compiler = '';
libloc = '';
vsinstalldir = '';
vcvarsopts = '';
mexopts = fullfile(prefdir,'mexopts.bat');
if ~exist(mexopts,'file')
  return
end
fid = fopen(mexopts);
while 1
  txt = fgetl(fid);
  if ~ischar(txt), break, end
  if isempty(compiler) && strncmp('rem ',txt,4)
		compiler = txt(5:end-8);
  %if strmatch('set COMPILER=',txt)
  %  compiler = txt(14:end);
  elseif ~isempty(strmatch('set LIBLOC=',txt))
    libloc = txt(20:end);
  elseif ~isempty(strmatch('set VSINSTALLDIR=',txt))
    vsinstalldir = txt(18:end);
    if ~isempty(strmatch(':\Program Files (x86)\',vsinstalldir(2:end)))
      vcvarsopts = 'x86_amd64';
    end
  end
end
fclose(fid);
