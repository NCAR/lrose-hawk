load('~/spowell/humidity_retrieval/diego/retarded.mat')

[A,B] = system('date +%Y%m%d');
datestamp = B(1:8);
clear A B
timestamp = '000000';

 figure(1)
pcolor(0:3:(numfiles-248-1)*3,0:0.1:(maxheight-0.1),ahum(:,249:end)), shading interp
set(gca,'XTick',[0:24:24*numfiles/8]);
set(gca,'XTickLabel',[0:1:numfiles/8]);
ylabel('Height (km)','FontSize',14);
xlabel('Days since November 1, 2011, 00Z','FontSize',14);
ylabel(colorbar,'Vapor Density (g m^{-3})');
title('Diego Garcia Soundings:  Vapor Density','FontSize',16);
%print -djpeg ahum.jpg

pname = strcat(['ahum_', datestamp, '_', timestamp, '.png']);

print ('-dpng', pname);

%return
close all

