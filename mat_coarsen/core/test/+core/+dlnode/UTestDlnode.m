classdef (Sealed) UTestDlnode < core.CoreFixture
    %UTestDlnode Unit test of the dlnode class.
    %   Detailed explanation goes here
    
    %=========================== CONSTRUCTORS ============================
    methods
        function self = UTestDlnode(name)
            self = self@core.CoreFixture(name);
        end
    end
    
    %=========================== TESTING METHODS =========================
    
    methods
        function testListOperations(self) %#ok<MANU>
            % Build a list
            n1=dlnode([1 2]);
            n2=dlnode(3);
            n3=dlnode([3 4 5]);
            n2.append(n3);
            n1.append(n2);
%            n3.insertAfter(n2);
%            n2.insertAfter(n1);

            assertEqual(n1.next, n2);
            assertEqual(n1.next.next, n3);
            assertEqual(n1.next.next.next, []);

            assertEqual(n1.data, [1 2]);
            assertEqual(n2.data, 3);
            
            % Must call updateList() to see changes in node.listData
            assertEqual(n1.listData, []);
            n1.updateListData();
            assertEqual(n1.listData, [1 2 3 3 4 5]);
            
            % The same holds when another node's data is updated
            n3.data = [4 5 7];
            assertEqual(n1.listData, [1 2 3 3 4 5]);
            n1.updateListData();
            assertEqual(n1.listData, [1 2 3 4 5 7]);
        end
    end
    
end

