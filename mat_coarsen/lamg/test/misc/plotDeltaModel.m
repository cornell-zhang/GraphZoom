deltaDecrement = 1.0;
rMax = 8.0;
r = (0:0.1:rMax)'; 
rSample = (0:deltaDecrement:rMax)';
delta = amg.coarse.deltaModel(r); 

figure(1);
clf;
h = plot(r, delta, 'b-', rSample, amg.coarse.deltaModel(rSample), 'rx');
set(h, 'LineWidth', 2);
set(h, 'MarkerSize', 10);
xlabel('r'); 
ylabel('\delta'); ylim([0 1]); 
shg; 
print -dpng delta_model.png
