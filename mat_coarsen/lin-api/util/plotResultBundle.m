function d = plotResultBundle(result, minEdges, outputDir, verbose, solvers, printType, fig, minLevels, threshold)
%PLOTACFRESULTBUNDLE Generate statistics plots of a cycle ACF batch run.
%   PLOTACFRESULTBUNDLE(RESULT) generates several plots depicting cycle
%   efficiency statistics from the data stored in the result bundle RESULT.
%   PLOTACFRESULTBUNDLE(RESULT, MINEDGES) restricts the statistics to
%   graphs with at most MINEDGES edges. If one argument is passed in,
%   MINEDGES = 40000 is used.
%
%   See also: RESULTBUNDLE.

%------------------------------------------
% Read input arguments
%------------------------------------------
config;
global GLOBAL_VARS           % Results output directory

if (nargin < 2)
    minEdges = 20000;
end
savePlots = (nargin >= 3) && ~isempty(outputDir);
if (nargin < 4)
    verbose = 2;
end

% Algorithm names
if (nargin < 5)
    solvers = {'lamg', 'lamgFlat', 'direct'};
end

if (nargin < 6)
    printType = 'paper';
end

if (nargin < 7)
    fig = 0;
end

if (nargin < 8)
    minLevels = 1; %2;
end

if (nargin < 9)
    threshold = 10.0;
end

%------------------------------------------
% Prepare data
%------------------------------------------
d = preparePlotData(result, minEdges, minLevels, solvers);
% TODO: fit linear curve to times

%------------------------------------------
% Text printouts
%------------------------------------------
if (verbose >= 1)
    printStats(1, d, threshold);
end
if (savePlots)
    fileName = strcat(GLOBAL_VARS.out_dir, '/', outputDir, '/', 'results.out');
    create_dir(fileName, 'file');
    f = fopen(fileName, 'w');
    printStats(f, d, threshold);
    fclose(f);
end

%------------------------------------------
% Plots
%------------------------------------------
if (verbose >= 2)
    fig=fig+1; figure(fig);
    plotTotalTimes(d, printType);
    saveCurrentFigure(savePlots, outputDir, 'solver_time');
    
    lamgPresent = isLamgPresent(d.solvers);
    for s = d.solvers
        solver = s{:};
        fig=fig+1; figure(fig);
        plotTimeBreakdown(d.(solver), printType);
        if (numel(d.solvers) > 1)
            % Uniform axis for solver comparison
            ylim([0 2000]);
        end
        saveCurrentFigure(savePlots, outputDir, sprintf('%s_breakdown', solver));
    end
    
    if (lamgPresent)
        % Plot LAMG ACF histogram
        fig=fig+1; figure(fig);
        hist(d.lamg.acf);
        h = findobj(gca,'Type','patch');
        set(h,'FaceColor',[0.6 0.6 0.6],'EdgeColor','k')
        xlabel('ACF');
        ylabel('Frequency');
        saveCurrentFigure(savePlots, outputDir, sprintf('%s_acf', 'lamg'));
        
        fig=fig+1; figure(fig);
        fontSize = getFontSize(printType);
        h = axes;
        set(h, 'FontSize', fontSize);
        semilogx(d.lamg.numEdges, d.lamg.storage, 'bo', 'MarkerSize', 6, 'LineWidth', 2);
        xlabel('# Edges', 'FontSize', fontSize);
        ylabel('Storage/edge', 'FontSize', fontSize);
        saveCurrentFigure(savePlots, outputDir, sprintf('%s_storage', solver));
        
        % Plot LAMG gain
        for s = d.solvers
            solver = s{:};
            if (~strcmp(solver, 'lamg'))
                fig=fig+1; figure(fig);
                gain = d.(solver).gain;
                gain(find(imag(gain))) = []; %#ok
                hist(gain);
                xlabel('Gain [log10]');
                ylabel('Frequency');
                saveCurrentFigure(savePlots, outputDir, sprintf('%s_lamg_gain', solver));
            end
        end
    end
end

% if (0)
%     % Plot ACF vs. graph size figure(100); clf;
%     semilogx(numEdges(nonTrivial), gain, 'k'); hold on;
%     plot(numEdges(nonTrivial), ones(1,numel(find(nonTrivial))), 'k--');
%     xlabel('# Edges'); ylabel('t_{solve,flat} / t_{solve}');
%
%     xlim([minEdges numEdges(end)]); if (savePlots)
%         save_figure('epsc', '%s/adaptive_gain.eps', outputDir);
%     end
%
%     % % Plot ACF per unit work vs. graph size figure(5); clf; %
%     semilogx(numEdges, beta, 'k'); xlabel('# Edges'); ylabel('\beta'); %
%     xlim([minEdges numEdges(end)]); if (savePlots) %
%     save_figure('epsc', '%s/beta.eps', outputDir); % end
% end
end

%----------------------------------------------------------------------
function d = preparePlotData(result, minEdges, minLevels, solvers)
% Prepare plot data: clean outliers = trivial matrices and restrict to an
% interesting graph size region. Return a data struct D whose fields are
% variables to be plotted.

numEdges    = cellfun(@(x)(x.numEdges), result.metadata);
% graphs      = find((numEdges >= minEdges) & ...
%     (result.dataColumns('lamgNumLevels') >= minLevels) & ...
%     allSucceeded);
lamgPresent = ~isempty(find(strcmp(result.fieldNames, 'lamgNumLevels'),1));
if (lamgPresent)
    graphs      = find((numEdges >= minEdges) & ...
        (result.dataColumns('lamgNumLevels') >= minLevels));
else
    graphs      = find(numEdges >= minEdges);
end
% Global statistics
[numEdges, index] = sort(result.data(graphs, result.fieldColumn('numEdges')));
i           = graphs(index);
tMvm        = result.data(i, result.fieldColumn('tMvm'));
d           = struct('size' , numel(i), 'minEdges', minEdges, 'numEdges', numEdges, ...
    'tMvm', tMvm);
d.originalData = struct('numNodes', result.dataColumns('numNodes'), ...
    'numEdges', result.dataColumns('numEdges'));
d.key       = cellfun(@(x)(x.key), result.metadata, 'UniformOutput', false);
d.solvers   = solvers;
isLamg      = isLamgPresent(d.solvers);

for s = solvers
    solver = s{:};
    data = struct();
    data.name       = solver;
    data.numEdges   = numEdges;
    data.success    = result.data(i, result.fieldColumn([solver 'Success']));
    data.tSetup     = result.data(i, result.fieldColumn([solver 'TSetup']));
    data.tSolve     = result.data(i, result.fieldColumn([solver 'TSolve']));
    data.tSetupMvm  = data.tSetup .* numEdges./ tMvm;
    data.tSolveMvm  = data.tSolve .* numEdges./ tMvm;
    data.details    = result.details(i);
    
    % Filter (but record) failures
    j                = find(data.success);
    data.index       = i(j); % Index of this solver's filtered results in the original result data array
    data.numFailures = numel(find(~data.success));
    data.numEdges    = numEdges(j,:);
    data.tMvm        = tMvm(j,:);
    data.success     = data.success(j,:);
    data.tSetup      = data.tSetup(j,:);
    data.tSolve      = data.tSolve(j,:);
    data.tSetupMvm   = data.tSetupMvm(j,:);
    data.tSolveMvm   = data.tSolveMvm(j,:);
    data.details     = data.details(j);
    
    acfField = [solver 'Acf'];
    if (result.fieldColumn.isKey(acfField))
        data.acf = result.data(i, result.fieldColumn([solver 'Acf']));
        % TODO: automatically locate the index k corresponding to LAMG
        if (numel(solvers) == 1)
            k = 1;
        else
            k = 2;
        end
        data.storage = 2*cellfun(@(x)(x{k}.setup.edgeComplexity), result.details(j));
    else
        data.storage = zeros(numel(j),1);
    end
    % TODO: replace this with a reusable if on solver type!1!!
    if (strcmp(solver, 'direct'))
        data.tTotal         = data.tSetup + data.tSolve;
        data.tTotalMvm      = data.tSolveMvm + data.tSetupMvm;
    else
        data.tTotal         = 10*data.tSolve + data.tSetup;
        data.tTotalMvm      = 10*data.tSolveMvm + data.tSetupMvm;
        data.setupFraction  = 100*data.tSetup./data.tTotal;
    end
    
    if (isLamg)
        refTSolve     = result.data(i, result.fieldColumn('lamgTSolve'));
        refTSetup     = result.data(i, result.fieldColumn('lamgTSetup'));
        refTTotal     = 10*refTSolve + refTSetup;
        data.gain     = log10(data.tTotal ./ refTTotal(j,:));
    end
    d.(solver) = data;
end

if (isLamgComparison(d.solvers))
    d.gain = d.lamgFlat.tSolve ./ (d.lamg.tSolve + eps);
end
end

%----------------------------------------------------------------------
function printStats(f, d, threshold)
% Print global statistics for all solvers.

fprintf(f, 'Statistics for %d graphs out of %d with at least %d edges:\n', ...
    d.size, numel(d.originalData.numNodes), d.minEdges);
isLamg = isLamgPresent(d.solvers);
for s = d.solvers
    solver = s{:};
    fprintf(f, 'Statistics: ''%s''\n', solver);
    printSolverStats(f, d.(solver));
    if (isLamg)
        gain = d.(solver).gain;
        fprintf(f, 'LAMG gain          : med=%.1f        mean=%.1f +- %.1f\n', ...
            median(gain), mean(gain), std(gain));
    end
    fprintf(f, '\n');
end
if (isLamgComparison(d.solvers))
    fprintf(f, 'Adaptive gain [sec]: median=%.3f%%      mean=%.3f%% +- %.3f%%\n', ...
        median(d.gain), mean(d.gain), std(d.gain));
end
%if (isLamgPresent(d.solvers)) solver = d.lamg;
for s = d.solvers
    solver = d.(s{:});
    solverStats = containers.Map({'tSetup', 'tSolve'}, {solver.tSetupMvm, solver.tSolveMvm});
    for statKey = solverStats.keys,
        stat        = statKey{:};
        solverStat  = solverStats(stat);
        med         = median(solverStat);
        slow        = solverStat >= threshold*med;
        index       = d.lamg.index(slow);
        key         = d.key(index);
        n           = d.originalData.numNodes(index);
        m           = d.originalData.numEdges(index);
        %statOfKey   = solverStat(slow);
        fprintf(f, '%s %s: %d outliers (threshold = %.1f, median = %.1f):\n', s{:}, stat, numel(key), threshold, med);
        if (isempty(key))
            fprintf(f, '  None\n');
        else
            [setup, solve] = deal(solver.tSetupMvm(slow), solver.tSolveMvm(slow));
            for i = 1:numel(key)
                fprintf(f, '  %-4d %-42s %-8d %-8d %6.1f %6.1f\n', index(i), key{i}, n(i), m(i), setup(i), solve(i));
            end
        end
    end
end
end

%----------------------------------------------------------------------
function printSolverStats(f, d)
% Print statistics for one solver.
fprintf(f, 'Failures: %d\n', d.numFailures);
fprintf(f, 'Total time    [sec]: med=%.1e   mean=%.1e +- %.1e  [MVM]: med=%5.1f   mean=%5.1f +- %5.1f\n', ...
    median(d.tTotal), mean(d.tTotal), std(d.tTotal), ...
    median(d.tTotalMvm), mean(d.tTotalMvm), std(d.tTotalMvm));
fprintf(f, 'Setup time    [sec]: med=%.1e   mean=%.1e +- %.1e  [MVM]: med=%5.1f   mean=%5.1f +- %5.1f\n', ...
    median(d.tSetup), mean(d.tSetup), std(d.tSetup), ...
    median(d.tSetupMvm), mean(d.tSetupMvm), std(d.tSetupMvm));
fprintf(f, 'Solve time    [sec]: med=%.1e   mean=%.1e +- %.1e  [MVM]: med=%5.1f   mean=%5.1f +- %5.1f\n', ...
    median(d.tSolve), mean(d.tSolve), std(d.tSolve), ...
    median(d.tSolveMvm), mean(d.tSolveMvm), std(d.tSolveMvm));
if (isfield(d, 'acf'))
    fprintf(f, 'ACF                : med=%.3f      mean=%.3f +- %.3f\n', ...
        median(d.acf), mean(d.acf), std(d.acf));
end
if (isfield(d, 'setupFraction'))
    fprintf(f, '%%Setup             : med=%5.1f%%     mean=%5.1f%% +- %5.1f%%\n', ...
        median(d.setupFraction), mean(d.setupFraction), std(d.setupFraction));
end
end

%----------------------------------------------------------------------
function plotTotalTimes(d, printType)
% Plot overall times for all solvers.
clf;
fontSize = getFontSize(printType);
h = axes;
set(h, 'FontSize', fontSize);

args = {};
legends = {};
colors = {'b', 'm', 'r'};
markers = {'x', 'o'};
i = 0;
for s = d.solvers
    i = i+1;
    solver = s{:};
    data = d.(solver);
    %args = [args, data.numEdges, data.tTotal .* data.numEdges, 'o']; %#ok
    if (strcmp(printType, 'slide'))
        args = [args, data.numEdges, data.tTotal .* data.numEdges, [colors{i} 'o']]; %#ok
    else
        args = [args, data.numEdges, data.tTotal .* data.numEdges, [markers{i} 'k']]; %#ok
    end
    legends = [legends, solver]; %#ok
end
args = [args, 'MarkerSize', 6, 'LineWidth', 2];
plots = loglog(args{:});
for i = 1:numel(plots)
    h = plots(i);
    d.(d.solvers{i}).plotTime = h;
    %color = get(h, 'Color'); set(h, 'MarkerFaceColor', color);
end

if (strcmp(printType, 'slide'))
    xlabel('# Links', 'FontSize', fontSize);
elseif (strcmp(printType, 'paper'))
    xlabel('# Edges', 'FontSize', fontSize);
    ylabel('Time [sec]', 'FontSize', fontSize);
    title('Solver Run Times', 'FontSize', fontSize);
end
legend(legends{:}, 'Location', 'Northwest');
xlim([min(d.numEdges) max(d.numEdges)]);

% Bring LAMG plot to top
if (isLamgPresent(d.solvers))
    h = d.lamg.plotTime;
    uistack(h, 'top');
end

end

%----------------------------------------------------------------------
function plotTimeBreakdown(data, printType)
% Plot setup, solve time vs. graph size for one solver.
clf;
fontSize = getFontSize(printType);
h = axes;
set(h, 'FontSize', fontSize);
%plots = ... if (strcmp(printType, 'slide'))
semilogx(data.numEdges, data.tSetupMvm, 'bo', ...
    data.numEdges, data.tSolveMvm, 'ro', 'MarkerSize', 6, 'LineWidth', 2);
% else
%     semilogx(data.numEdges, data.tSetupMvm, 'kx', ...
%         data.numEdges, data.tSolveMvm, 'ko', 'MarkerSize', 6,
%         'LineWidth', 2);
% end for i = 1:numel(plots)
%     h = plots(i); color = get(h, 'Color'); set(h, 'LineWidth', 2);
%     %set(h, 'MarkerFaceColor', color); %set(h, 'MarkerEdgeColor', 'k');
% end
if (strcmp(printType, 'slide'))
    xlabel('# Links', 'FontSize', fontSize);
    ylabel('Time [MVM]', 'FontSize', fontSize);
    title(sprintf('%s Time Breakdown', upper(data.name)), 'FontSize', fontSize);
    legend('Setup time per edge', 'Solve time per edge per unit \epsilon', ...
        'Location', 'Northwest');
elseif (strcmp(printType, 'paper'))
    xlabel('# Edges', 'FontSize', fontSize);
    ylabel('Time [MVM]', 'FontSize', fontSize);
end
xlim([min(data.numEdges) max(data.numEdges)]);
%ylim([1e-8 1e-4]); ylim([0 2000]); xlim([1e5 4e7]);
end

%----------------------------------------------------------------------
function saveCurrentFigure(savePlots, outputDir, figureTitle)
% Save figure in output directory
if (savePlots)
    save_figure('epsc', '%s/%s.eps', outputDir, figureTitle);
    save_figure('png' , '%s/%s.png', outputDir, figureTitle);
end
end

%----------------------------------------------------------------------
function flag = isLamgPresent(solvers)
% Is LAMG in the list of analyzed solvers?
flag = ismember('lamg', solvers);
end

%----------------------------------------------------------------------
function flag = isLamgComparison(solvers)
% Are we comparing LAMG adaptive energy correction with LAMG flat energy
% correction in this run?
flag = (ismember('lamg', solvers) && ismember('lamgFlat', solvers));
end

%----------------------------------------------------------------------
function fontSize = getFontSize(printType)
% Compute the font size for a print profile.
if (strcmp(printType, 'paper'))
    fontSize = 14;
elseif (strcmp(printType, 'slide'))
    fontSize = 20;
end
end