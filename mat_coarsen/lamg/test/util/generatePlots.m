% Generate plots for LAMG paper

% LAMG - Beagle
r = load('c:\oren\out\beagle\beagle_results_2012_03_10.mat');
r = r.r;
r.remove([1477 571 1697]); % Remove outliers in the generated ml directory
d = plotResultBundle(r, 50000, 'beagle-2012-03-10', 2, {'lamg'}, 'paper', 1, 1, 7.0);

% LAMG vs. CMG - Dell
r = load('c:\oren\out\2012-02-08\cycle_results.mat');
r = r.result;
r.remove([1949 2403 2609]); % Remove outliers in the generated ml directory
d = plotResultBundle(r, 50000, 'dell-2012-02-08', 2, {'lamg', 'cmg'}, 'paper', 1, 1, 7.0);
