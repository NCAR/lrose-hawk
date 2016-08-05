function read_gan_matfiles(sounding_dir)

%Date:  October 9, 2011
%Author:  S. Powell, UW
%Description:  Time series of absolute humidity and relative humidity in lower trop.

%Add long-term mean sounding as reference?

close all; clc;

%User defined parameter...How high do we want to go (in km or hPa)?
maxheight = 20; %km
minpress = 50; %hPa

system('ls -C1 ~/projDir/data/matlab/gan/matfiles/201*.mat > files.read_gan_matfiles');
[A,B] = system('wc -l files.read_gan_matfiles');
numfiles = sscanf(B,'%d %*s');

fprintf('--->>> numfiles: %d\n', numfiles);

ahum = nan(300,numfiles); 
ihgt = nan(300,numfiles); 
awind = nan(300,numfiles);
amwind = nan(300,numfiles); 
azwind = nan(300,numfiles);
atemp = nan(300,numfiles); 
apress = nan(300,numfiles);
Z = nan(300,numfiles);
iP = nan(110,numfiles);

fid = fopen('files.read_gan_matfiles'); 

for j = 1:numfiles
  clear rhgt rP P T Z u v dewpt wind winddir rh mwind zwind;
  fname = strcat(fscanf(fid,'%s',1));
  fprintf('--->>> loading file: %s\n', fname);
  load(fname)
  rh(rh == 9999) = NaN;
  dewpt(dewpt == 99999) = NaN;
  wind(wind == 99999) = NaN;
  winddir(winddir == 999) = NaN;
  mwind = -wind.*cosd(winddir);
  zwind = -wind.*sind(winddir);
  rhgt = 0.1*round(hgt*10);
  rP = 10*round(0.1*P);
  if isnan(max(P)) == 1
    ihgt; iP;
  else
    ihgt(1:length(unique(rhgt)),j) = unique(rhgt);
    iP(1:length(unique(rP)),j) = sort(unique(rP),'descend');  
  end
  for k = 1:numel(ihgt(:,j))
    arh(k,j) = nanmean(rh(rhgt == ihgt(k,j)));
    atemp(k,j) = nanmean(T(rhgt == ihgt(k,j)));
    ahum(k,j) = nanmean(abshum(rhgt == ihgt(k,j)));
    amwind(k,j) = nanmean(mwind(rhgt == ihgt(k,j)));
    azwind(k,j) = nanmean(zwind(rhgt == ihgt(k,j)));
  end
  for k = 1:numel(iP(:,j))
    aZ(k,j) = nanmean(Z(rP == iP(k,j)));
  end
end

fclose(fid);

%atemp(:,end) = [];  %numfiles = N, but size(everythingelse,2) = N-1...weird

ahum = ahum(1:maxheight*10,:); ihgt = ihgt(1:maxheight*10,:); awind = awind(1:maxheight*10,:); arh = arh(1:maxheight*10,:);
amwind = amwind(1:maxheight*10,:); azwind = azwind(1:maxheight*10,:);
atemp = atemp(1:maxheight*10,:); 
aZ = aZ(1:0.1*(1010-minpress),:);
apress = apress(1:maxheight*10,:);
%contour(ahum(1:20,:),ihgt(1:20,1))
timemean = nanmean(ahum');
azmean = nanmean(azwind');
ammean = nanmean(amwind');
Zmean = nanmean(aZ');
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
for k = 1:size(aZ,1)
  for l = 1:size(aZ,2)
    Zresid(k,l) = aZ(k,l) - Zmean(k);
  end
end

system('rm -f files.read_gan_matfiles');

save('~/projDir/data/matlab/gan/retarded.mat');

quit(0);
