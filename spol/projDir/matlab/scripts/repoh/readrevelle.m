%Date:  October 15, 2011
%Author:  S. Powell, UW
%Description:  Read in Roger Revelle soundings and plot data.

clear all; close all; clc;
Rstar = 287;
maxheight = 20;

system('ls -C1 ~/spowell/humidity_retrieval/revelle/data/*.nc > out');
filenames = [];
fid = fopen('out');
[A,B] = system('wc -l out');
numfiles = sscanf(B,'%d %*s');

for i = 1:numfiles
  fname= fscanf(fid,'%s',1);
  filenames = [filenames, {fname}];
end
fclose(fid);

ahum = nan(300,numfiles); ihgt = nan(300,numfiles); awind = nan(300,numfiles);
amwind = nan(300,numfiles); azwind = nan(300,numfiles);
atemp = nan(300,numfiles);

%There are some files that are missing.  To fill in the gaps, I copied a file from a random time and gave it a name ending in hh0000.nc.  All the values in corresponding to these columns should be set to NaN;

%iss2_sounding.D20111001_030000.nc
%iss2_sounding.D20111001_060000.nc
%iss2_sounding.D20111001_090000.nc
%iss2_sounding.D20111003_180000.nc
%iss2_sounding.D20111013_030000.nc
%iss2_sounding.D20111013_180000.nc

for j = 1:size(filenames,2)
  clear P T Td rh u v wind winddir hgt rho esat e abshum
  
  ncid = netcdf.open(cell2mat(filenames(j)),'NC_NOWRITE');

  P = netcdf.getVar(ncid,3);
  T = netcdf.getVar(ncid,4);
  Td = netcdf.getVar(ncid,5);
  rh = netcdf.getVar(ncid,6);
  u = netcdf.getVar(ncid,7);
  v = netcdf.getVar(ncid,8);
  wind = netcdf.getVar(ncid,9);
  winddir = netcdf.getVar(ncid,10);
  hgt = netcdf.getVar(ncid,26);

  if length(cell2mat(filenames(j))) ~= 92  %Bad file
    P(~isnan(P)) = NaN;
    T(~isnan(T)) = NaN;
    Td(~isnan(Td)) = NaN;
    rh(~isnan(rh)) = NaN;
    u(~isnan(u)) = NaN;
    v(~isnan(v)) = NaN;
    hgt(~isnan(hgt)) = NaN;
    wind(~isnan(wind)) = NaN;
    winddir(~isnan(winddir)) = NaN;
    rho = P;
  else
  %Set to NaNs.
    P(P==-999) = NaN;
    T(T==-999) = NaN;
    Td(Td==-999) = NaN;
    rh(rh==-999) = NaN;
    u(u==-999) = NaN;
    v(v==-999) = NaN;
    hgt(hgt==-999) = NaN;
    hgt = 0.001*hgt;  %Convert to km.
    rho = 100*P./(Rstar.*(T+273.15)); %(kg m^-3) 
  end
 
  esat = nan(length(T),1);
  esat(T>0,1) = 0.6108*exp((17.27*T(T>0))./(T(T>0)+237.3));       %Over water
  esat(T<=0,1) = 0.6108*exp((21.875*T(T<=0))./(T(T<=0)+265.5));   %Over ice
  %Convert relative humidity to absolute humidity in g kg^-1.
  e = 0.01*esat.*rh;  %Multiply sat vapor pressure by RH.
  abshum = ((2165.*e)./(T+273.16))./rho; %in g kg^-1.

  clear rhgt;
  rhgt = 0.1*round(hgt*10);
  ihgt(1:length(unique(rhgt)),j) = unique(rhgt);
  for k = 1:numel(unique(rhgt))
    arh(k,j) = nanmean(rh(rhgt == ihgt(k,j)));
    ahum(k,j) = nanmean(abshum(rhgt == ihgt(k,j)));
    amwind(k,j) = nanmean(v(rhgt == ihgt(k,j)));
    azwind(k,j) = nanmean(u(rhgt == ihgt(k,j)));
    atemp(k,j) = nanmean(T(rhgt == ihgt(k,j)));
  end
  ahum = ahum(1:maxheight*10,:); ihgt = ihgt(1:maxheight*10,:); awind = awind(1:maxheight*10,:); arh = arh(1:maxheight*10,:);
  amwind = amwind(1:maxheight*10,:); azwind = azwind(1:maxheight*10,:);
  atemp = atemp(1:maxheight*10,:);

  timemean = nanmean(ahum');
  azmean = nanmean(azwind');
  ammean = nanmean(amwind');
  Tmean = nanmean(atemp');
  for k = 1:size(ahum,1)
    for l = 1:size(ahum,2)
      residual(k,l) = ahum(k,l) - timemean(k);
      amresid(k,l) = amwind(k,l) - ammean(k);
      azresid(k,l) = azwind(k,l) - azmean(k);
      Tresid(k,l) = atemp(k,l) - Tmean(k);
      frdiff(k,l) = 100*(residual(k,l)./timemean(k));
    end
  end

  netcdf.close(ncid);

end

%Don't know why we need this...
ahum = double(ahum); arh = double(arh); frdiff = double(frdiff); amwind = double(amwind); amresid = double(amresid); azwind = double(azwind); azresid = double(azresid);
atemp = double(atemp);

system('rm -f out');

save('~/spowell/humidity_retrieval/revelle/retarded.mat')

return

