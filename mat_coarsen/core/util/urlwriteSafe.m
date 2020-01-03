function urlwriteSafe(url, filename)
%URLWRITESAFE A URLWRITE version that does not require a JVM.
%   Same as URLWRITE(URL,FILENAME) without a return value, but also works
%   with MCC executables that were compiled with -R -nojvm. Useful on
%   Beagle.
%
%   See also: URLWRITE.

if (isdeployed)
    % Assuming linux
    system(['wget ' url ' -O ' filename ' -q']);
else
    urlwrite(url, filename);
end

end
