load('~/spowell/humidity_retrieval/diego/retarded.mat')

[A,B] = system('date +%Y%m%d');
datestamp = B(1:8);
clear A B
timestamp = '000000';

 figure(7)
pcolor(0:3:(numfiles-248-1)*3,0:0.1:(maxheight-0.1),azresid(:,249:end)), shading interp, colormap(flipud(baroclinic)), caxis([-10 10])
set(gca,'XTick',[0:24:24*numfiles/8]);
set(gca,'XTickLabel',[0:1:numfiles/8]);
ylabel('Height (km)','FontSize',14);
xlabel('Days since November 1, 2011, 00Z','FontSize',14);
ylabel(colorbar,'Zonal wind anomaly (m s^{-1})','FontSize',14);
title('Diego Garcia soundings:  Zonal wind anomalies','FontSize',16);

pname = strcat(['uwindanom_', datestamp, '_', timestamp, '.png']);

print ('-dpng', pname);

%return
close all

