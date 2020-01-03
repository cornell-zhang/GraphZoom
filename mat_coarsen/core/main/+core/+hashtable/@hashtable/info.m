function info(this)

% Display information about this hashtable.
fprintf('              size: %d\n', this.size);
fprintf('number of elements: %d\n', this.numel);
fprintf('           loading: %.2g\n', this.numel / this.size);
fprintf('       load factor: %.2g\n', this.load);
fprintf('     growth factor: %.2g\n', this.grow);

ne = 0;
mc = 0;
for i = 1:this.size
    if this.index(i,1) == 0
        ne = ne + 1;
    end
    j = 0;
    while this.index(i,j+1) ~= 0
        j = j + 1;
    end
    mc = max(mc, j);
end

fprintf('      unused slots: %d\n', ne);
fprintf('     longest chain: %d\n', mc);   
