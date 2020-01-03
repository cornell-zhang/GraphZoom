% graph reduction

%input:
% mtx file:  input graph Laplacian matrix

%output:
% Gs:        reduced graph Laplacian matrix
% setup:     data structure for storing all information of reduction
% 		     setup.level{i}.R: mapping operator between level i and i-1

function LamgSetup()
        fprintf('Loading Graph to be Reduced......\n');
        GraphPath = "cora.mtx"
        ReductionRatio = 2
        Fusion = false;                                    % whether used for fusion kernel
        SavePath = 'save'
        lda = 0.1;                                         % self_loop
        kpower = 2;                                        % power of graph filter

        fp = fopen(GraphPath, 'r');
        B = textscan(fp, '%d %d %f', 'headerlines', 3);    % skip first two rows in mtx file
        row = cell2mat(B(1));
        col = cell2mat(B(2));
        val = cell2mat(B(3));
        fclose(fp);

        A = sparse(double(row), double(col), double(val));
        if(~issymmetric(A))
            A = A'+A-diag(diag(A));
        end
        n = length(A);	
        fprintf('###### Running LamgSetup ######\n');
        t = cputime;
	    lamg  = Solvers.newSolver('lamg', 'randomSeed', 1,  'maxDirectSolverSize', floor(n/ReductionRatio), 'lda', lda, 'kpower', kpower);

        %tStart = tic;
        setup = lamg.setup('laplacian', A);
	    %tSetup = toc(tStart);
	    disp(setup)
    
	    %setRandomSeed(now);
        
	    lv = length(setup.level);
        assert(lv>=2, 'ERROR: Reduction ratio is too small, plese try ReductionRatio > 2 !!!!!!\n');
	    X = setup.level{2}.R; % R is m-by-n
        if ~Fusion
            writeMtx(X, nnz(X), strcat(SavePath,'/Projection_1.mtx'));
            A = setup.level{2}.R*A*setup.level{2}.R';
        end
        
        i = 3;
	    while(lv > 2 & i <= lv)
            X = setup.level{i}.R * X;
            if ~Fusion
                A = setup.level{i}.R*A*setup.level{i}.R';
                writeMtx(setup.level{i}.R, nnz(setup.level{i}.R), strcat(SavePath,'/Projection_',num2str(i-1),'.mtx'));
            end
	        i = i+1;
	    end
        cpu_time = cputime - t;
        writeMtx(X, nnz(X), strcat(SavePath,'/Mapping.mtx'));
        if ~Fusion
            dlmwrite(sprintf(strcat(SavePath,'/NumLevels.txt')), lv);
            writematrix(A, nnz(A), strcat(SavePath,'/Gs.mtx'));
        end
        dlmwrite(sprintf(strcat(SavePath,'/CPUtime.txt')), cpu_time);
 end
