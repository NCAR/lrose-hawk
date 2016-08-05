%Date:  Dec 14 2011
%Author:  Mike Dixon, NCAR
%Description:  Read in Gan files, save in single mat file

function combine_gan(ganDataDir, ...
                     fileListStr)

% compute list of file paths, from the fileListStr

fprintf('combine_gan, reading data from dir: %s\n', ganDataDir);
fileNameList = regexp(fileListStr, ',', 'split');
numFiles = length(fileNameList);
fprintf('Number of gan input files: %d\n', numFiles);

% initialize

maxheight = 20; %km
minpress = 50; %hPa

ahum = nan(300,numFiles); 
ihgt = nan(300,numFiles); 
awind = nan(300,numFiles);
amwind = nan(300,numFiles); 
azwind = nan(300,numFiles);
atemp = nan(300,numFiles); 
apress = nan(300,numFiles);
Z = nan(300,numFiles);
iP = nan(110,numFiles);

% loop through files

for (ii = 1:length(fileNameList))

  clear rhgt rP P T Z u v dewpt wind winddir rh mwind zwind;

  fileName = cell2mat(fileNameList(ii));
  filePath = strcat([ganDataDir, '/matfiles/', fileName]);

  fprintf('--->>> loading file: %s\n', filePath);
  load(filePath)
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
    ihgt(1:length(unique(rhgt)),ii) = unique(rhgt);
    iP(1:length(unique(rP)),ii) = sort(unique(rP),'descend');  
  end
  for kk = 1:numel(ihgt(:,ii))
    arh(kk,ii) = nanmean(rh(rhgt == ihgt(kk,ii)));
    atemp(kk,ii) = nanmean(T(rhgt == ihgt(kk,ii)));
    ahum(kk,ii) = nanmean(abshum(rhgt == ihgt(kk,ii)));
    amwind(kk,ii) = nanmean(mwind(rhgt == ihgt(kk,ii)));
    azwind(kk,ii) = nanmean(zwind(rhgt == ihgt(kk,ii)));
  end
  for kk = 1:numel(iP(:,ii))
    aZ(kk,ii) = nanmean(Z(rP == iP(kk,ii)));
  end

end

combinedMatFilePath = strcat([ganDataDir, 'retarded.mat']);
save(combinedMatFilePath);
fprintf('--->>> Saved combined mat file: %s\n', combinedMatFilePath);

% quit(0);
