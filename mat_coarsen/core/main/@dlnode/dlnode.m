classdef dlnode < handle
    %DLNODE  A class to represent a doubly-linked list node.
    %   Multiple dlnode objects may be linked together to create linked
    %   lists. Each node contains a piece of data and provides access to
    %   the next andprevious nodes.
    
    %======================== PROPERTIES ==============================
    properties
        data            % This node's data
    end
    properties (SetAccess = private)
        next            % Reference to next node in the list
        prev            % Reference to previous node in the list
        listData        % Assuming data is a list, a concatenation of the data of this node and all subsequent nodes on the list. Manually set by updateListData() call.
    end
    
    %======================== CONSTRUCTORS ============================
    methods
        function node = dlnode(data)
            % DLNODE  Constructs a dlnode object.
            if nargin > 0
                node.data = data;
            end
        end
    end
    
    %======================== METHODS =================================
    methods
        function insertAfter(newNode, nodeBefore)
            % insertAfter  Inserts newNode after nodeBefore.
            disconnect(newNode);
            newNode.next = nodeBefore.next;
            newNode.prev = nodeBefore;
            if ~isempty(nodeBefore.next)
                nodeBefore.next.prev = newNode;
            end
            nodeBefore.next = newNode;
        end
        
        function insertBefore(newNode, nodeAfter)
            % insertBefore  Inserts newNode before nodeAfter.
            disconnect(newNode);
            newNode.next = nodeAfter;
            newNode.prev = nodeAfter.prev;
            if ~isempty(nodeAfter.prev)
                nodeAfter.prev.next = newNode;
            end
            nodeAfter.prev = newNode;
        end
        
        function disconnect(node)
            % DISCONNECT  Removes a node from a linked list. The node can
            % be reconnected or moved to a different list.
            if ~isscalar(node)
                error('Nodes must be scalar')
            end
            prevNode = node.prev;
            nextNode = node.next;
            if ~isempty(prevNode)
                prevNode.next = nextNode;
            end
            if ~isempty(nextNode)
                nextNode.prev = prevNode;
            end
            node.next = [];
            node.prev = [];
        end
        
%         function delete(node)
%             % DELETE  Deletes a dlnode from a linked list.
%             disconnect(node);
%         end
%         
        function append(node1, node2)
            % append  Concatenate the linked lists starting with node1 and
            % node 2. Does not check for cycles so will block if list1
            % contains a cycle.
            
            % Find the last node in the list of node1
            lastNode = node1;
            nextNode = lastNode.next;
            while (~isempty(nextNode))
                lastNode = nextNode;
                nextNode = lastNode.next;
            end
            
            % Append node2 at the end of the node1 list
            lastNode.next   = node2;
            node2.prev      = lastNode;
        end

        function listData = updateListData(node)
            % Updates the list data field and returns it. Does not check
            % for cycles. Will block forever if the linked list has a
            % cycle.
            
            % Concatenation without pre-allocation is slow. Allocate first.
            sz          = 0;
            nextNode    = node;
            while (~isempty(nextNode))
                sz          = sz + numel(nextNode.data);
                nextNode    = nextNode.next;
            end
            listData     = zeros(1, sz);
            
            % Now populate listData with the data of all nodes
            index           = 0;
            nextNode        = node;
            while (~isempty(nextNode))
                nextData    = nextNode.data;
                currentSz   = numel(nextData);
                listData(index+1:index+currentSz) = nextData;
                nextNode    = nextNode.next;
                index       = index + currentSz;
            end
            
            % Save in this object
            node.listData = listData;
        end

        function disp(node)
            % DISP  Display a link node.
            if (isscalar(node))
                disp('Doubly-linked list node with data:')
                disp(node.data)
            else % If node is an object array, display dims only
                dims = size(node);
                ndims = length(dims);
                for k = ndims-1:-1:1
                    dimcell{k} = [num2str(dims(k)) 'x'];
                end
                dimstr = [dimcell{:} num2str(dims(ndims))];
                disp([dimstr ' array of doubly-linked list nodes']);
            end
        end
    end % methods
    
    %======================== GET & SET ===============================
    methods
    end
    
end % classdef
