% hashtable class test script
%
% Tests adding/removing hashtable entries using various types of keys and
% values, etc.  Not exhaustive!
% 
% Make sure @hashtable is in your path before running this!
%
import core.hashtable.*;

fast_hash = @(x)(double(x));
fast_eq = @eq;

while true
    dkeys = rand(200, 1) * 100000;
    ikeys = int32(dkeys);
    if length(unique(ikeys)) == length(ikeys)
        break;
    end
end

skeys = cell(200,1);
for i = 1:200
    skeys{i} = num2str(ikeys(i));
end
    
nvals = rand(200, 1) * 1000;
svals = cell(200, 1);
for i = 1:200
    svals{i} = num2str(nvals(i), 10);
end

fprintf('Testing hashtable construction...');
x = hashtable;
x = hashtable('size', 10);
x = hashtable('load', 0.9);
x = hashtable('equals', @eq);
x = hashtable('hash', fast_hash);
x = hashtable('grow', 3.0);
x = hashtable('size', 10, 'load', 0.9, 'equals', @eq, 'hash', fast_hash, 'grow', 3.0);
fprintf(' OK\n');

fprintf('Testing real keys (defaults)...');
x = hashtable;
for i = 1:length(dkeys)
    x = put(x, dkeys(i), nvals(i));
end
success = true;
for i = 1:length(dkeys)
    v = get(x, dkeys(i));
    if v ~= nvals(i)
        success = false;
        break;
    end
end
if success
    fprintf(' OK\n');
else
    fprintf(' FAIL\n');
end

fprintf('Testing integer keys (defaults)...');
x = hashtable;
for i = 1:length(ikeys)
    x = put(x, ikeys(i), nvals(i));
end
success = true;
for i = 1:length(ikeys)
    v = get(x, ikeys(i));
    if v ~= nvals(i)
        success = false;
        break;
    end
end
if success
    fprintf(' OK\n');
else
    fprintf(' FAIL\n');
end

fprintf('Testing string keys (defaults)...');
x = hashtable;
for i = 1:length(skeys)
    x = put(x, skeys{i}, nvals(i));
end
success = true;
for i = 1:length(skeys)
    v = get(x, skeys{i});
    if v ~= nvals(i)
        success = false;
        break;
    end
end
if success
    fprintf(' OK\n');
else
    fprintf(' FAIL\n');
end

fprintf('Testing real keys (fast equals and hash)...');
x = hashtable('hash', fast_hash, 'equals', fast_eq);
for i = 1:length(dkeys)
    x = put(x, dkeys(i), nvals(i));
end
success = true;
for i = 1:length(dkeys)
    v = get(x, dkeys(i));
    if v ~= nvals(i)
        success = false;
        break;
    end
end
if success
    fprintf(' OK\n');
else
    fprintf(' FAIL\n');
end

fprintf('Testing string values...');
x = hashtable;
for i = 1:length(dkeys)
    x = put(x, dkeys(i), svals{i});
end
success = true;
for i = 1:length(dkeys)
    v = get(x, dkeys(i));
    if ~strcmp(v, svals{i})
        success = false;
        break;
    end
end
if success
    fprintf(' OK\n');
else
    fprintf(' FAIL\n');
end

fprintf('Testing Set behavior...');
x = hashtable;
for i = 1:length(dkeys)
    x = put(x, dkeys(i));
end
success = true;
for i = 1:length(dkeys)
    if ~has_key(x, dkeys(i))
        success = false;
    end
    if has_key(x, skeys{i})
        success = false;
    end
end
if success
    fprintf(' OK\n');
else
    fprintf(' FAIL\n');
end


fprintf('Testing item updates...');
x = hashtable;
for i = 1:length(dkeys)
    x = put(x, dkeys(i), nvals(i));
end
success = true;
for i = 1:length(dkeys)
    v = get(x, dkeys(i));
    if v ~= nvals(i)
        success = false;
        break;
    end
end
for i = 1:length(dkeys)
    x = put(x, dkeys(i), svals{i});
end
for i = 1:length(dkeys)
    v = get(x, dkeys(i));
    if ~strcmp(v, svals{i})
        success = false;
        break;
    end
end
if count(x) ~= length(dkeys)
    success = false;
end
if success
    fprintf(' OK\n');
else
    fprintf(' FAIL\n');
end

fprintf('Testing hashtable growth...');
x = hashtable('size', 1);
for i = 1:length(dkeys)
    x = put(x, dkeys(i));
end
if count(x) == length(dkeys)
    fprintf(' OK\n');
else
    fprintf(' FAIL\n');
end

fprintf('Testing struct keys...');
x = hashtable;
st1 = struct;
st1.foo = 'test';
st1.bar = 44;
st2 = struct;
st2.foo = 'nope';
st2.bar = 44;
st3 = struct;
st3.foo = 'test';
st4 = struct;
st4.blah = 100;

x = put(x, st1, 1);
x = put(x, st2, 2);
x = put(x, st3, 3);
x = put(x, st4, 4);

success = false;
if count(x) == 4
    if get(x, st1) == 1 && get(x, st2) == 2 && get(x, st3) == 3 && get(x, st4) == 4
        x = put(x, st1, 'apple');
        if strcmp(get(x, st1), 'apple')
            success = true;
        end
    end
end
if success
    fprintf(' OK\n');
else
    fprintf(' FAIL\n');
end


fprintf('Testing vector/matrix/multidimensional array keys...');
x = hashtable;
x = put(x, zeros(3), 'foo');
x = put(x, eye(2), 'bar');
x = put(x, magic(5), 'snafu');
x = put(x, 1:0.2:10, 'urg');
x = put(x, (5:6)', 'huh');
x = put(x, reshape(magic(9), [3 3 1 9]), 'yikes!');

success = false;
if strcmp(get(x, zeros(3)), 'foo')
    if strcmp(get(x, eye(2)), 'bar')
        if strcmp(get(x, magic(5)), 'snafu')
            if strcmp(get(x, 1:0.2:10), 'urg')
                if strcmp(get(x, (5:6)'), 'huh')
                    if strcmp(get(x, reshape(magic(9), [3 3 1 9])), 'yikes!')
                        success = true;
                    end
                end
            end
        end
    end
end
if success
    fprintf(' OK\n');
else
    fprintf(' FAIL\n');
end

fprintf('Testing cell array keys...');
x = hashtable;
x = put(x, {'hey' 'world'}, 99);
x = put(x, {1 1 2 3 5 8 13}, 'phi');
x = put(x, {sqrt(2) sqrt(3); sqrt(5) sqrt(7); sqrt(11) sqrt(13)});

success = false;
if get(x, {'hey' 'world'}) == 99
    if strcmp(get(x, {1 1 2 3 5 8 13}), 'phi')
        if has_key(x, {sqrt(2) sqrt(3); sqrt(5) sqrt(7); sqrt(11) sqrt(13)})
            success = true;
        end
    end
end
if success
    fprintf(' OK\n');
else
    fprintf(' FAIL\n');
end

fprintf('Testing OOPS object keys...');
x = hashtable;
a = pumpkin(4);
b = pumpkin(5);
c = pumpkin(4);
x = put(x, a, pi);
x = put(x, b, atan(1));
x = put(x, c, cos(40));
success = (get(x, a) == cos(40)) && (get(x, b) == atan(1)) && (count(x) == 2);
if success
    fprintf(' OK\n');
else
    fprintf(' FAIL\n');
end


fprintf('Testing composite/mixed keys...');
x = hashtable;
p = {st1 4 'hello'; a [1 2 3] {'second' 'level'}};
x = put(x, 4);
x = put(x, 'foo');
x = put(x, svals);
x = put(x, p);
success = has_key(x, 4) && has_key(x, 'foo') && has_key(x, svals) && has_key(x, p);
if success
    fprintf(' OK\n');
else
    fprintf(' FAIL\n');
end

fprintf('Testing dump...');
x = hashtable;
for i = 1:length(skeys)
    x = put(x, skeys{i}, svals{i});
end
[k, v] = dump(x);

success = all(strcmp(sort(k), sort(skeys))) && all(strcmp(sort(v), sort(svals)));
if success
    fprintf(' OK\n');
else
    fprintf(' FAIL\n');
end

fprintf('Testing miscellaneous other...');
% stress test on grow and load parameters
x = hashtable('size', 5, 'grow', 1.1, 'load', 0.25);
for i = 1:length(dkeys)
    x = put(x, dkeys(i));
end
success = true;
for i = 1:length(dkeys)
    if ~has_key(x, dkeys(i))
        success = false;
        break;
    end
end

% test get on non-keys
x = hashtable;
success = success && isempty(get(x, 'bleah'));
success = success && ~has_key(x, 0);
success = success && ~has_key(x, []);
success = success && ~has_key(x, dkeys);

if success
    fprintf(' OK\n');
else
    fprintf(' FAIL\n');
end


