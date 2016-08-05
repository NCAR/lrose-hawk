load('~/spowell/humidity_retrieval/revelle/retarded.mat')

[A,B] = system('date +%Y%m%d');
datestamp = B(1:8);
clear A B
timestamp = '000000';

figure(5)
pcolor(0:3:(numfiles-237-1)*3,0:0.1:(maxheight-0.1),amresid(:,238:end)), shading interp, colormap(flipud(baroclinic)), caxis([-10 10])
set(gca,'XTick',[0:24:24*numfiles/8]);
set(gca,'XTickLabel',[0:1:numfiles/8]);
ylabel('Height (km)','FontSize',14);
xlabel('Days since November 8, 2011, 00Z','FontSize',14);
ylabel(colorbar,'Meridional wind anomaly (m s^{-1})','FontSize',14);
title('Revelle soundings:  Meridional wind anomalies','FontSize',16);

pname = strcat(['vwindanom_', datestamp, '_', timestamp, '.png']);

print ('-dpng', pname);

%return
close all


