function product_driver(today)

%*******THIS IS FOR DAILY PRODUCTS.*******

%Date:  October 11, 2011
%Author:  S. Powell, UW
%Description:  Driver program for batch_view_repoh.

close all, clear h; clc;

%***********USER DEFINED PARAMETERS*****************

snding_select = 'y';  %Enter 'y' to plot soundings, 'n' for no.
avg_snding = 'y';     %Compute mean DOE sounding over the period for which you wish to view data?
oneplot = 'y';        %Plot everything on one plot? ('y' or 'n').
azi_sep = 'y';        %Separate by sectors (SW,NW,SE,NE); recall beam blockage to west requires only scans >= 2.5deg to be included.
azibin = [0:90:360];  %Create analysis sectors by azimuth angle.  %Sectors must start at 0deg!
hgt_lev = 0.25;	      %What are sizes of height bins?
show_scat = 'n';      %Show a scatter plot?
repoh_mean = 'y';     %One big REPoH mean over the time period selected.  Will do for each azimuth if azi_sep is 'y'.
gm3 = 'n';	      %View in g m^-3 (y) or g kg^-1 (n)?

% Where are the sounding matfiles?

sounding_dir = '~/projDir/data/matlab/sounding/matfiles/';

% Where are the REPoH ascii files?

repoh_ascii_dir = '~/projDir/data/matlab/REPoH/ascii';

% userview dir

userview_dir = '~/projDir/data/matlab/REPoH/userview';

hgtbin = [0:hgt_lev:5];  %Height bins for REPoH.
modeset = 100;

% ======= 02Z ========

cd(repoh_ascii_dir);
command = 'ls -C1 *_0[0,1,2]*.ascii > ../out.1 ';
fprintf('running command: %s\n', command);
system(command);

cd(userview_dir);
filenames = [];
fid3 = fopen('../out.1');
[A,B] = system('wc -l ../out.1');
numfiles = sscanf(B,'%d %*s');
for i = 1:numfiles
  name = fscanf(fid3,'%c',31);
  filenames = [filenames {name}];
end
fclose(fid3);
batch_view_repoh(today, filenames, snding_select, avg_snding, oneplot, azi_sep, azibin, hgtbin, hgt_lev, show_scat, repoh_mean, gm3, repoh_ascii_dir, sounding_dir, '02');
figname = strcat(['repoh_' today '_000000.png']);
title(strcat([today, ' 00Z-03Z']),'FontSize',16)
d = text(15,4.9,'Median profiles plotted, color-coded by sector.');
set(d,'HorizontalAlignment','center');
g = text(15,4.6,'If no valid retrievals, no line is plotted.');
set(g,'HorizontalAlignment','center');
e = text(15,4.3,'Bars contain 80 percent of retrieval points.');
set(e,'HorizontalAlignment','center');
f = text(15,4.0,'Solid black line represents sounding.');
set(f,'HorizontalAlignment','center');
print ('-dpng',figname), close all, clear h
  
% ======= 05Z ==========

  cd(repoh_ascii_dir);
command = 'ls -C1 *_0[3,4,5]*.ascii > ../out.2 ';
fprintf('running command: %s\n', command);
system(command);

%Get filenames
cd(userview_dir);
filenames = [];
fid3 = fopen('../out.2');
[A,B] = system('wc -l ../out.2');
numfiles = sscanf(B,'%d %*s');
for i = 1:numfiles
  name = fscanf(fid3,'%c',31);
  filenames = [filenames {name}];
end
fclose(fid3);
batch_view_repoh(today, filenames, snding_select, avg_snding, oneplot, azi_sep, azibin, hgtbin, hgt_lev, show_scat, repoh_mean, gm3, repoh_ascii_dir, sounding_dir, '05');
figname = strcat(['repoh_' today '_030000.png']);
title(strcat([today, ' 03Z-06Z']),'FontSize',16)
d = text(15,4.9,'Median profiles plotted, color-coded by sector.');
set(d,'HorizontalAlignment','center');
g = text(15,4.6,'If no valid retrievals, no line is plotted.');
set(g,'HorizontalAlignment','center');
e = text(15,4.3,'Bars contain 80 percent of retrieval points.');
set(e,'HorizontalAlignment','center');
f = text(15,4.0,'Solid black line represents sounding.');
set(f,'HorizontalAlignment','center');
print ('-dpng',figname), close all, clear h

% ======= 08Z ==========

cd(repoh_ascii_dir);
command = 'ls -C1 *_0[6, 7, 8]*.ascii > ../out.3 ';
fprintf('running command: %s\n', command);
system(command);

%Get filenames
cd(userview_dir);

filenames = [];
fid3 = fopen('../out.3');
[A,B] = system('wc -l ../out.3');
numfiles = sscanf(B,'%d %*s');
for i = 1:numfiles
  name = fscanf(fid3,'%c',31);
  filenames = [filenames {name}];
end
fclose(fid3);
batch_view_repoh(today, filenames, snding_select, avg_snding, oneplot, azi_sep, azibin, hgtbin, hgt_lev, show_scat, repoh_mean, gm3, repoh_ascii_dir, sounding_dir, '08');
figname = strcat(['repoh_' today '_060000.png']);
title(strcat([today, ' 06Z-09Z']),'FontSize',16)
d = text(15,4.9,'Median profiles plotted, color-coded by sector.');
set(d,'HorizontalAlignment','center');
g = text(15,4.6,'If no valid retrievals, no line is plotted.');
set(g,'HorizontalAlignment','center');
e = text(15,4.3,'Bars contain 80 percent of retrieval points.');
set(e,'HorizontalAlignment','center');
f = text(15,4.0,'Solid black line represents sounding.');
set(f,'HorizontalAlignment','center');
print ('-dpng',figname), close all, clear h

% ======= 11Z ==========

cd(repoh_ascii_dir);
command = 'ls -C1 *_09*.ascii *_1[0, 1]*.ascii > ../out.4 ';
fprintf('running command: %s\n', command);
system(command);

%Get filenames
cd(userview_dir);
filenames = [];
fid3 = fopen('../out.4');
[A,B] = system('wc -l ../out.4');
numfiles = sscanf(B,'%d %*s');
for i = 1:numfiles
  name = fscanf(fid3,'%c',31);
  filenames = [filenames {name}];
end
fclose(fid3);
batch_view_repoh(today, filenames, snding_select, avg_snding, oneplot, azi_sep, azibin, hgtbin, hgt_lev, show_scat, repoh_mean, gm3, repoh_ascii_dir, sounding_dir, '11');
figname = strcat(['repoh_' today '_090000.png']);
title(strcat([today, ' 09Z-12Z']),'FontSize',16)
d = text(15,4.9,'Median profiles plotted, color-coded by sector.');
set(d,'HorizontalAlignment','center');
g = text(15,4.6,'If no valid retrievals, no line is plotted.');
set(g,'HorizontalAlignment','center');
e = text(15,4.3,'Bars contain 80 percent of retrieval points.');
set(e,'HorizontalAlignment','center');
f = text(15,4.0,'Solid black line represents sounding.');
set(f,'HorizontalAlignment','center');
print ('-dpng',figname), close all, clear h

% ======= 14Z ==========

cd(repoh_ascii_dir);
command = 'ls -C1 *_1[2, 3, 4]*.ascii > ../out.5 ';
fprintf('running command: %s\n', command);
system(command);

%Get filenames
cd(userview_dir);
filenames = [];
fid3 = fopen('../out.5');
[A,B] = system('wc -l ../out.5');
numfiles = sscanf(B,'%d %*s');
for i = 1:numfiles
  name = fscanf(fid3,'%c',31);
  filenames = [filenames {name}];
end
fclose(fid3);
batch_view_repoh(today, filenames, snding_select, avg_snding, oneplot, azi_sep, azibin, hgtbin, hgt_lev, show_scat, repoh_mean, gm3, repoh_ascii_dir, sounding_dir, '14');
figname = strcat(['repoh_' today '_120000.png']);
title(strcat([today, ' 12Z-15Z']),'FontSize',16)
d = text(15,4.9,'Median profiles plotted, color-coded by sector.');
set(d,'HorizontalAlignment','center');
g = text(15,4.6,'If no valid retrievals, no line is plotted.');
set(g,'HorizontalAlignment','center');
e = text(15,4.3,'Bars contain 80 percent of retrieval points.');
set(e,'HorizontalAlignment','center');
f = text(15,4.0,'Solid black line represents sounding.');
set(f,'HorizontalAlignment','center');
print ('-dpng',figname), close all, clear h

% ======= 17Z ==========

cd(repoh_ascii_dir);
command = 'ls -C1 *_1[5, 6, 7]*.ascii > ../out.6 ';
fprintf('running command: %s\n', command);
system(command);

%Get filenames
cd(userview_dir);
filenames = [];
fid3 = fopen('../out.6');
[A,B] = system('wc -l ../out.6');
numfiles = sscanf(B,'%d %*s');
for i = 1:numfiles
  name = fscanf(fid3,'%c',31);
  filenames = [filenames {name}];
end
fclose(fid3);
batch_view_repoh(today, filenames, snding_select, avg_snding, oneplot, azi_sep, azibin, hgtbin, hgt_lev, show_scat, repoh_mean, gm3, repoh_ascii_dir, sounding_dir, '17');
figname = strcat(['repoh_' today '_150000.png']);
title(strcat([today, ' 15Z-18Z']),'FontSize',16)
d = text(15,4.9,'Median profiles plotted, color-coded by sector.');
set(d,'HorizontalAlignment','center');
g = text(15,4.6,'If no valid retrievals, no line is plotted.');
set(g,'HorizontalAlignment','center');
e = text(15,4.3,'Bars contain 80 percent of retrieval points.');
set(e,'HorizontalAlignment','center');
f = text(15,4.0,'Solid black line represents sounding.');
set(f,'HorizontalAlignment','center');
print ('-dpng',figname), close all, clear h

% ======= 20Z ==========

cd(repoh_ascii_dir);
command = 'ls -C1 *_1[8, 9]*.ascii *_20*.ascii > ../out.7 ';
fprintf('running command: %s\n', command);
system(command);

%Get filenames
cd(userview_dir);
filenames = [];
fid3 = fopen('../out.7');
[A,B] = system('wc -l ../out.7');
numfiles = sscanf(B,'%d %*s');
for i = 1:numfiles
  name = fscanf(fid3,'%c',31);
  filenames = [filenames {name}];
end
fclose(fid3);
batch_view_repoh(today, filenames, snding_select, avg_snding, oneplot, azi_sep, azibin, hgtbin, hgt_lev, show_scat, repoh_mean, gm3, repoh_ascii_dir, sounding_dir, '20');
figname = strcat(['repoh_' today '_180000.png']);
title(strcat([today, ' 18Z-21Z']),'FontSize',16)
d = text(15,4.9,'Median profiles plotted, color-coded by sector.');
set(d,'HorizontalAlignment','center');
g = text(15,4.6,'If no valid retrievals, no line is plotted.');
set(g,'HorizontalAlignment','center');
e = text(15,4.3,'Bars contain 80 percent of retrieval points.');
set(e,'HorizontalAlignment','center');
f = text(15,4.0,'Solid black line represents sounding.');
set(f,'HorizontalAlignment','center');
print ('-dpng',figname), close all, clear h

% ======= 23Z ==========

cd(repoh_ascii_dir);
command = 'ls -C1 *_2[1, 2, 3]*.ascii > ../out.8 ';
fprintf('running command: %s\n', command);
system(command);

%Get filenames
cd(userview_dir);
filenames = [];
fid3 = fopen('../out.8');
[A,B] = system('wc -l ../out.8');
numfiles = sscanf(B,'%d %*s');
for i = 1:numfiles
  name = fscanf(fid3,'%c',31);
  filenames = [filenames {name}];
end
fclose(fid3);
batch_view_repoh(today, filenames, snding_select, avg_snding, oneplot, azi_sep, azibin, hgtbin, hgt_lev, show_scat, repoh_mean, gm3, repoh_ascii_dir, sounding_dir, '23');
figname = strcat(['repoh_' today '_210000.png']);
title(strcat([today, ' 21Z-24Z']),'FontSize',16)
d = text(15,4.9,'Median profiles plotted, color-coded by sector.');
set(d,'HorizontalAlignment','center');
g = text(15,4.6,'If no valid retrievals, no line is plotted.');
set(g,'HorizontalAlignment','center');
e = text(15,4.3,'Bars contain 80 percent of retrieval points.');
set(e,'HorizontalAlignment','center');
f = text(15,4.0,'Solid black line represents sounding.');
set(f,'HorizontalAlignment','center');
print ('-dpng',figname), close all, clear h

% ============ All ==========

system('cat ../out.1 ../out.2 ../out.3 ../out.4 ../out.5 ../out.6 ../out.7 ../out.8 > ../out.all');
filenames = [];
fid3 = fopen('../out.all');
[A,B] = system('wc -l ../out.all');
numfiles = sscanf(B,'%d %*s');
for i = 1:numfiles
  name = fscanf(fid3,'%c',31);
  filenames = [filenames {name}];
end
fclose(fid3);
batch_view_repoh(today, filenames, snding_select, avg_snding, oneplot, azi_sep, azibin, hgtbin, hgt_lev, show_scat, repoh_mean, gm3, repoh_ascii_dir, sounding_dir, '');
figname = strcat(['repoh_all_' today '_230000.png']);
title(strcat([today, ': All Soundings']),'FontSize',16)
d = text(15,4.9,'Median profiles plotted, color-coded by sector.');
set(d,'HorizontalAlignment','center');
g = text(15,4.6,'If no valid retrievals, no line is plotted.');
set(g,'HorizontalAlignment','center');
e = text(15,4.3,'Bars contain 80 percent of retrieval points.');
set(e,'HorizontalAlignment','center');
f = text(15,4.0,'Solid black line represents mean daily sounding.');
set(f,'HorizontalAlignment','center');
c = text(15,3.7,'Dashed lines are max/min sounding humidity.');
set(c,'HorizontalAlignment','center');
print ('-dpng',figname), close all, clear h

quit(0);

