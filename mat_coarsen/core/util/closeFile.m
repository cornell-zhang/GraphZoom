function closeFile(f)
%CLOSEFILE Close an open file. Catch all exceptions
%   CLOSEFILE(F) closes the file identified by the identifier F. Suitable
%   for error handling within a code that uses FOPEN.
%
%   See also: FOPEN, FCLOSE.


% Make sure to close open file
try
    if (f >= 0)
        fclose(f);
    end
catch e
    % I/O exception, ignore
end

end
