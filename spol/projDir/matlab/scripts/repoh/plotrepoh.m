%Date: October 5, 2011
%Author:  S. Powell, UW
%Description:  Plot absolute humidity profiles for REPoH retrievals.

%NEED TO CONVERT TO G M^-3!

clear rhgt;

system('ls -c1 *.out > temp');
[A,B] = system('wc -l temp');
numfiles = sscanf(B,'%d %*s');
clear A, clear B;

%Constants
Rprime = (4/3)*6375; %Earth radius (km)

fid = fopen('temp');
for i = 1:numfiles
  clear sounding, clear hgt, clear abshum; clear hgtbin; clear humbin;
  fname = strcat(fscanf(fid,'%c',20));
  load(fname)
  hour(i) = str2num(fname(14:15));
  fid2 = fopen(fname);
  command = strcat('[AA,BB] = system(''wc -l');
  command = horzcat(command,' ',fname,''');');
  eval(command);
  numlines = sscanf(BB,'%d %*s');

  if numlines ~= 0
    for j = 1:numlines
      sounding(j,:) = fscanf(fid2,'%f %f %f %f %f %f',6);
    end

    %Determine height of midpoint of ray.
    phi = sounding(:,1); %Azimuth angle
    Rb = sounding(:,3); Re = sounding(:,4); %Beginning and ending range;
    abshum = sounding(:,6);  %Humidity in g/m^3
    R = 0.5*(Rb + Re); %Range of midpoint of ray.
    hgt = sqrt(R.^2 + Rprime.^2 + 2.*R.*Rprime.*sind(phi)) - Rprime;

    savename = strcat(fname(1:8),'_',fname(14:15),'Z.mat');
    save(savename,'hgt','abshum');
  end
% Scatter plot by hour.
%scatter(abshum(:,i),hgt(:,i))
end

system('rm temp');


