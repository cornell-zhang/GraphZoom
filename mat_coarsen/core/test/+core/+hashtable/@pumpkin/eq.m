function b = eq(this, obj)

b = strcmp(class(obj), 'pumpkin') && this.val == obj.val;