load('~/spowell/humidity_retrieval/sounding/matfiles/retarded.mat')

[A,B] = system('date +%Y%m%d');
datestamp = B(1:8);
clear A B
timestamp = '000000';

figure(8)
pcolor(0:3:(numfiles-248-240-1)*3,0:0.1:(maxheight-0.1),Tresid(:,489:end)), shading interp, colormap(baroclinic), caxis([-5 5])
set(gca,'XTick',[0:24:24*numfiles/8]);
set(gca,'XTickLabel',[0:1:numfiles/8]);
ylabel('Height (km)','FontSize',14);
xlabel('Days since December 1, 2011, 00Z','FontSize',14);
ylabel(colorbar,'Temperature anomaly (K)','FontSize',14);
title('Gan soundings:  Temperature anomalies','FontSize',16);

pname = strcat(['Tanom_', datestamp, '_', timestamp, '.png']);

print ('-dpng', pname);

%return
close all

