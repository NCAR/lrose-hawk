load('~/spowell/humidity_retrieval/male/retarded.mat')

[A,B] = system('date +%Y%m%d');
datestamp = B(1:8);
clear A B
timestamp = '000000';

figure(7)
pcolor(0:6:(numfiles-124-120-1)*6,0:0.1:(maxheight-0.1),Tresid(:,245:end)), shading interp, colormap(baroclinic), caxis([-5 5])
set(gca,'XTick',[0:24:24*numfiles/4]);
set(gca,'XTickLabel',[0:1:numfiles/4]);
ylabel('Height (km)','FontSize',14);
xlabel('Days since December 1, 2011, 00Z','FontSize',14);
ylabel(colorbar,'Temperature anomaly (K)','FontSize',14);
title('Male soundings:  Temperature anomalies','FontSize',16);

pname = strcat(['Tanom_', datestamp, '_', timestamp, '.png']);

print ('-dpng', pname);

%return
close all

