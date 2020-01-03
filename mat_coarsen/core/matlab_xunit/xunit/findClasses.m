function classes = findClasses(packageName, varargin)
%FINDCLASSES return a filtered list of classes under a package.
%
%   @param packageName package name
%
%   @param regex (varargin) list of class name regular expressions to
%   match
%
%   @return classes list of fully qualified class names under
%   packageName

import core.util.*;
%            fprintf('Scanning package %s\n',packageName);
regex = getInputNames(varargin{:});

classes = {};
info = meta.package.fromName(packageName);
if (info.isvalid)
    % Add classes in this package
    packageClasses = info.Classes;
    if (~isempty(packageClasses))
        for i = 1:length(packageClasses)
            className = packageClasses{i}.Name;
            if (matches(className, regex))
                classes{end+1} = className;
            end
        end
    end
    % Recursively scan all sub-packages and add their classes
    subPackages = info.Packages;
    if (~isempty(subPackages))
        for i = 1:length(subPackages)
            subPacakgeClasses = ...
                findClasses(subPackages{i}.Name, varargin{:});
            classes = [classes subPacakgeClasses ];
        end
    end
end
