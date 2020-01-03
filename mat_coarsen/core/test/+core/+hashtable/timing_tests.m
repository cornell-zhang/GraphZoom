classdef (Sealed) timing_tests
    methods (Static)
        function run
            % hashtable timing tests: performance at different sizes of hashtable
            % compared with linear search (using MATLAB find()), struct field lookup
            % (an alternative dictionary approach), and Java hashtable callout.
            import core.hashtable.*;
            
            p = struct;
            
            %p.sizes = [10, 100, 1e3, 1e4, 2e4, 3e4, 4e4, 5e4];
            p.sizes = [10, 100, 1e3, 1e4];
            
            for Nidx = 1:length(p.sizes)
                N = p.sizes(Nidx);
                
                fprintf('Testing performance on hashtable with %d entries...\n', N);
                
                dkeys = rand(1,N) * 1000;
                skeys = cell(1,N);
                qidx = ceil(rand(1,1000) * N);
                
                for i = 1:N
                    skeys{i} = ['a' regexprep(num2str(dkeys(i), 20), '.', '_')];
                end
                
                %%% Real keys
                q = dkeys(qidx);
                
                % Hashtable performance
                dx = hashtable('size', 1.4 * N);
                for i = 1:N
                    dx = put(dx, dkeys(i), i);
                end
                
                start = cputime;
                for i = 1:1000
                    k = q(i);
                    v = get(dx, k);
                end
                runtime = cputime - start;
                fprintf('Time to find 1000 real keys in hashtable: %.2g\n', runtime);
                p.rhashtable(Nidx) = runtime;
                clear dx;
                
                % Find performance
                start = cputime;
                for i = 1:1000
                    k = q(i);
                    v = find(dkeys == k);
                end
                runtime = cputime - start;
                fprintf('Time to find 1000 real keys using find(): %.2g\n', runtime);
                p.rfind(Nidx) = runtime;
                
                % Java hashtable performance
                jx = java.util.Hashtable(1.4 * N);
                for i = 1:N
                    jx.put(dkeys(i), i);
                end
                
                start = cputime;
                for i = 1:1000
                    k = q(i);
                    v = jx.get(k);
                end
                runtime = cputime - start;
                fprintf('Time to find 1000 real keys in Java Hashtable: %.2g\n', runtime);
                p.rjava(Nidx) = runtime;
                clear jx;
                
                % optimized real hashtable performance
                dx = hashtable('size', 1.4 * N, 'equals', @eq, 'hash', @(x)(x));
                for i = 1:N
                    dx = put(dx, dkeys(i), i);
                end
                
                start = cputime;
                for i = 1:1000
                    k = q(i);
                    v = get(dx, k);
                end
                runtime = cputime - start;
                fprintf('Time to find 1000 real keys in optimized hashtable: %.2g\n', runtime);
                p.ropthash(Nidx) = runtime;
                clear dx;
                
                %%% String keys
                
                % Hashtable performance
                sx = hashtable('size', 1.4 * N);
                for i = 1:N
                    sx = put(sx, skeys{i}, i);
                end
                
                start = cputime;
                for i = 1:1000
                    k = skeys{qidx(i)};
                    v = get(sx, k);
                end
                runtime = cputime - start;
                fprintf('Time to find 1000 string keys in hashtable: %.2g\n', runtime);
                p.shashtable(Nidx) = runtime;
                clear sx;
                
                % Struct field lookup performance
                sx = struct;
                for i = 1:N
                    sx.(skeys{i}) = i;
                end
                
                start = cputime;
                for i = 1:1000
                    k = skeys{qidx(i)};
                    v = sx.(k);
                end
                runtime = cputime - start;
                fprintf('Time to find 1000 string keys using struct field lookup: %.2g\n', runtime);
                p.sstruct(Nidx) = runtime;
                clear sx;
                
                % Java hashtable performance
                jx = java.util.Hashtable(1.4 * N);
                for i = 1:N
                    jx.put(skeys{i}, i);
                end
                
                start = cputime;
                for i = 1:1000
                    k = skeys{qidx(i)};
                    v = jx.get(k);
                end
                runtime = cputime - start;
                fprintf('Time to find 1000 string keys in Java Hashtable: %.2g\n', runtime);
                p.sjava(Nidx) = runtime;
                clear jx;
            end
            
            fprintf('\n\n===============================\n\n');
            fprintf('Summary of performance: \n');
            fprintf('Table size:      ');
            for i = 1:length(p.sizes)
                fprintf('\t%d', p.sizes(i));
            end
            fprintf('\nReal keys:\n');
            fprintf('MATLAB Hashtable:');
            for i = 1:length(p.sizes)
                fprintf('\t%.2g', p.rhashtable(i));
            end
            fprintf('\noptimized Hashtable:   ');
            for i = 1:length(p.sizes)
                fprintf('\t%.2g', p.ropthash(i));
            end
            fprintf('\nMATLAB find():   ');
            for i = 1:length(p.sizes)
                fprintf('\t%.2g', p.rfind(i));
            end
            fprintf('\nJava Hashtable:  ');
            for i = 1:length(p.sizes)
                fprintf('\t%.2g', p.rjava(i));
            end
            
            fprintf('\n\nString keys:\n');
            fprintf('MATLAB Hashtable:');
            for i = 1:length(p.sizes)
                fprintf('\t%.2g', p.shashtable(i));
            end
            fprintf('\nstruct field lookup:');
            for i = 1:length(p.sizes)
                fprintf('\t%.2g', p.sstruct(i));
            end
            fprintf('\nJava Hashtable:  ');
            for i = 1:length(p.sizes)
                fprintf('\t%.2g', p.sjava(i));
            end
            
            fprintf('\n\n');
        end
    end
end