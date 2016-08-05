load('~/spowell/humidity_retrieval/male/retarded.mat')

[A,B] = system('date +%Y%m%d');
datestamp = B(1:8);
clear A B
timestamp = '000000';

figure(2)
pcolor(0:6:(numfiles-125-1)*6,0:0.1:(maxheight-0.1),double(arh(:,126:end))), shading interp, caxis([0 100]), colorbar;
set(gca,'XTick',[0:24:24*numfiles/4]);
set(gca,'XTickLabel',[0:1:numfiles/4]);
ylabel('Height (km)','FontSize',14);
xlabel('Days since November 1, 2011, 00Z','FontSize',14);
ylabel(colorbar,'Relative Humidity (%)');
title('Male Soundings:  Relative Humidity','FontSize',16);
%print -djpeg rh.jpg

pname = strcat(['rh_', datestamp, '_', timestamp, '.png']);

print ('-dpng', pname)
%return
close all



