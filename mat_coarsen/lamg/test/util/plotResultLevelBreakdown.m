function s = plotResultLevelBreakdown(r, index)
% Correlate slow graphs with graph statistics

s = r.details{index}{1}.setup;
%lev = 1:s.numLevels;
n = s.nodes;
m = s.edges;
fac = s.edges ./ s.edges(1);

figure;
%fig=fig+1;
clf;
semilogx(m, s.timeRelax ./ s.numTv , 'bo', m, s.timeCoarsening, 'ro', m, s.timeOther, 'go');
xlabel('#Edges in Level');
ylabel('Setup Time / edge');
legend('TV Relax', 'Galerkin', 'Other', 'Location', 'Northwest');
xlim([1e4 2*s.edges(1)]);
ylim([1e-8 1e-6]);
shg;

figure;
%fig=fig+1;
clf;
semilogx(n, s.timeRelax ./ s.numTv , 'bo', n, s.timeCoarsening, 'ro', n, s.timeOther, 'go');
xlabel('#Nodes in Level');
ylabel('Setup Time / edge');
legend('TV Relax', 'Galerkin', 'Other', 'Location', 'Northwest');
xlim([1e4 2*s.edges(1)]);
ylim([1e-8 1e-6]);
shg;

if (0)
figure;
%fig=fig+1;
clf;
semilogx(m, fac .* s.timeRelax ./ s.numTv , 'bo', m, fac.*s.timeCoarsening, 'ro', m, fac.*s.timeOther, 'go');
xlabel('#Edges in Level');
ylabel('Setup Time / fine edge');
legend('TV Relax', 'Galerkin', 'Other', 'Location', 'Northwest');
xlim([1e4 2*s.edges(1)]);
shg;
end

end
