function read_in_gan(fname)

%Date:  October 1, 2011
%Author:  S. Powell, UW
%Description:  Read in Gan Sounding; convert RH to absolute humidity in g kg^-1.

%Data format
%Minutes Seconds AscRate(m/s) Hgt(m) Pressure(hPa) Temp(C) RH(%) Dewpt(C) WindDir(deg) WindSpd(m/s)
%Data begins at Line 28 before reformatted.
%Last 24 lines need to be cut off before reformatting.

%% Read in file names and number of sounding levels.

%Probably a better way to do this..

fprintf('====>> read_in_gan, fname: %s\n', fname);

command = strcat('[AA,BB] = system(''wc -l');
command = horzcat(command,' ',fname,''');');
eval(command); 
numlevs = sscanf(BB,'%d %*s');

%Constants.
g = 9.81; Rstar = 287;
g0 = 9.78; %At equator
Re = 6371000; %Radius of Earth in meters.

%Read in sounding data.
fid = fopen(fname);
clear esat sounding winddata wind winddir abshum e rho 
for i = 1:numlevs
  sounding(i,:) = fscanf(fid,'%d %d %f %f %f %f %f %f',8);
  winddata(i,:) = fscanf(fid,'%f %f',2);
end

%% Make calculations.

%Get air density.
P = sounding(:,5);
T = sounding(:,6);
hgt = 0.001*sounding(:,4);
rh = sounding(:,7);
dewpt = sounding(:,8);
winddir = winddata(:,1);
wind = winddata(:,2);
rho = 100*P./(Rstar.*(T+273.15)); %(kg m^-3)

geopot = g0.*((Re./(Re+hgt*1000)).^2).*(hgt*1000); %B/c height at surface is zero!
Z = geopot/g0;

if (rh == 9999)
   rh = NaN;
end

if (dewpt == 99999)
  dewpt = NaN;
end

% Saturation vapor pressure in kPa.  Equations from Teton (1930).
esat(T>0,1) = 0.6108*exp((17.27*T(T>0))./(T(T>0)+237.3));	%Over water
esat(T<=0,1) = 0.6108*exp((21.875*T(T<=0))./(T(T<=0)+265.5));  	%Over ice

% Convert relative humidity to absolute humidity in g kg^-1. 
e = 0.01*esat.*sounding(:,7);  %Multiply sat vapor pressure by RH.
abshum = ((2165.*e)./(T+273.16))./rho; %in g kg^-1.

kk = findstr(fname, 'gansonderawM1');

yearstr = fname((kk(1) + 17):(kk(1)+20));
monthstr = fname((kk(1) + 21):(kk(1)+22));
daystr = fname((kk(1) + 23):(kk(1)+24));
hourstr = fname((kk(1) + 26):(kk(1)+27));
daystr = fname((kk(1) + 17):(kk(1)+24));

year = str2num(yearstr);
month = str2num(monthstr);
day = str2num(daystr);
hour = str2num(hourstr);

savedir = '~/projDir/data/matlab/gan/matfiles/tmp/';
command = strcat(['mkdir -p ', savedir]);
fprintf('running command: %s\n', command);
system(command);

savefile = 'notset';
fprintf('year: %s\n', yearstr);
fprintf('month: %s\n', monthstr);
fprintf('day: %s\n', daystr);
fprintf('hour: %s\n', hourstr);
fprintf('daystr: %s\n', daystr);

% Adjust sounding time for easy referencing by REPoH processor.
% expected hours are 02, 05, 08, 11, 14, 17, 20, 23

savehourstr = hourstr;

if (hour < 3)
  savehourstr = '02';
elseif (hour < 6)
  savehourstr = '05';
elseif (hour < 9)
  savehourstr = '08';
elseif (hour < 12)
  savehourstr = '11';
elseif (hour < 15)
  savehourstr = '14';
elseif (hour < 18)
  savehourstr = '17';
elseif (hour < 21)
  savehourstr = '20';
else
  savehourstr = '23';
end

savefile = strcat(savedir, daystr, '_', savehourstr, 'Z');

fprintf('savefile: %s\n', savefile);

save(savefile,'rho','abshum','hgt','P','T','dewpt','rh','wind','winddir','geopot','Z');
