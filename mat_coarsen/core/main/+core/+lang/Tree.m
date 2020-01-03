classdef (Sealed) Tree < handle
    %TREE A simple tree implementation.
    %   TREE has a bi-directional association to its children nodes. It
    %   supports adding and removing children.
    
    %=========================== PROPERTIES ==============================
    properties (GetAccess = public, SetAccess = private)
        children    % Children node cell array. Methods can still be called on this mutable cell array. TODO: prevent this in the future so that it can be accessed only through methods in this class.
        parent      % Reference to this node's parent node. If it is empty, this is the root node.
    end
    
    %=========================== CONSTRUCTORS ============================
    methods
        function obj = Tree(children)
            %Construct a tree node.
            if ((nargin < 0) || (nargin > 1))
                error('MATLAB:Logger:InputArg','Must pass 1 constructor argument');
            else
                if (nargin >= 1)
                    obj.addChildren(children);
                end
            end
        end
    end
    
    %=========================== METHODS =================================
    methods
        function addChild(obj, child)
            %Append a child node to this node.
            obj.children{end+1} = child;
            child.parent = obj;
        end

        function addChildren(obj, children)
            %Append multiple children to this node.
            for i = 1:children.length
                obj.addChild(children{i});
            end
        end
        
        function removeChild(obj, index)
            %Remove child with index "index" in the children list.
            child = obj.children{index};
            obj.children(index) = {}; % See http://www.mathworks.com/matlabcentral/newsreader/view_thread/164617
            child.parent = [];
        end

    end
    
    %=========================== GET & SET ===============================

    %=========================== PRIVATE METHODS =========================
    methods (Access = private)
        
    end
end
