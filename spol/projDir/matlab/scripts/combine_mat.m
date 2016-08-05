%Date:  Dec 14 2011
%Author:  Mike Dixon, NCAR
%Description:  Read in mat files, save in single mat file

function combine_mat(matDataDir, ...
                     combinedMatFilePath, ...
                     fileListStr)

% compute list of file paths, from the fileListStr

fprintf('combing_mat, reading data from dir: %s\n', matDataDir);
fileNameList = regexp(fileListStr, ',', 'split');
numFiles = length(fileNameList);
fprintf('Number of mat input files: %d\n', numFiles);

% initialize

maxHeight = 20; %km
nLevels = maxHeight * 10;
minpress = 50; %hPa

ahum = nan(300,numFiles); 
ihgt = nan(300,numFiles); 
awind = nan(300,numFiles);
amwind = nan(300,numFiles); 
azwind = nan(300,numFiles);
atemp = nan(300,numFiles); 
apress = nan(300,numFiles);
iP = nan(110,numFiles);

% loop through files

fileDates = []

for (ii = 1:length(fileNameList))

  clear rhgt rP P T u v dewpt wind winddir rh mwind zwind;

  fileName = cell2mat(fileNameList(ii));
  filePath = strcat([matDataDir, '/matfiles/', fileName]);

  % get date and time from file name

  datePos = strfind(fileName, '201');
  dateStr = fileName(datePos:datePos+7);
  spacerStr = fileName(datePos+8:datePos+8);

  if (spacerStr == '_' || spacerStr == '.')
    % yyyymmdd_hhmmss or yyyymmdd.hhmmss
    timeStr = fileName(datePos+9:datePos+14);
  else
    % yyyymmddhmm
    timeStr = fileName(datePos+8:datePos+13);
  end

  year = str2num(dateStr(1:4));
  month = str2num(dateStr(5:6));
  day = str2num(dateStr(7:8));

  hour = str2num(timeStr(1:2));
  min = str2num(timeStr(3:4));

  if (spacerStr == '_' || spacerStr == '.')
    sec = str2num(timeStr(5:6));
  else
    sec = 0;
  end

  fileDate = datenum([year month day hour min sec]);
  
  fprintf('--->>> loading file: %s\n', filePath);
  fprintf('       File date/time: %.4d/%.2d/%.2d %.2d:%.2d:%.2d\n', ...
          year, month, day, hour, min, sec);

  load(filePath)
  rh(rh<0) = NaN;
  rh(rh>100) = NaN;
  wind(wind < -100) = NaN;
  wind(wind > 100) = NaN;
  winddir(winddir < -360) = NaN;
  winddir(winddir > 360) = NaN;
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
    rhtest = nanmean(rh(rhgt == ihgt(kk,ii)));
    atemp(kk,ii) = nanmean(T(rhgt == ihgt(kk,ii)));
    adp(kk,ii) = nanmean(Td(rhgt == ihgt(kk,ii)));
    ahum(kk,ii) = nanmean(abshum(rhgt == ihgt(kk,ii)));
    amwind(kk,ii) = nanmean(mwind(rhgt == ihgt(kk,ii)));
    azwind(kk,ii) = nanmean(zwind(rhgt == ihgt(kk,ii)));
  end

  ahum = ahum(1:nLevels,:);
  ihgt = ihgt(1:nLevels,:);
  awind = awind(1:nLevels,:);
  arh = arh(1:nLevels,:);
  amwind = amwind(1:nLevels,:);
  azwind = azwind(1:nLevels,:);
  atemp = atemp(1:nLevels,:);

  timemean = nanmean(ahum');
  azmean = nanmean(azwind');
  ammean = nanmean(amwind');
  Tmean = nanmean(atemp');
  for k = 1:size(ahum,1)
    for l = 1:size(ahum,2)
      residual(k,l) = ahum(k,l) - timemean(k);
      amresid(k,l) = amwind(k,l) - ammean(k);
      azresid(k,l) = azwind(k,l) - azmean(k);
      tresid(k,l) = atemp(k,l) - Tmean(k);
      frdiff(k,l) = 100*(residual(k,l)./timemean(k));
    end
  end

  fileDates(ii) = fileDate;

end % ii

% make sure we have doubles
ahum = double(ahum);
arh = double(arh);
frdiff = double(frdiff);
amwind = double(amwind);
amresid = double(amresid);
azwind = double(azwind);
azresid = double(azresid);
tresid = double(tresid);

save(combinedMatFilePath, ...
     'numFiles', 'fileDates', ...
     'maxHeight', 'nLevels', ...
     'ahum', 'arh', 'frdiff', 'amwind', ...
     'amresid', 'azwind', 'azresid', 'tresid');

fprintf('--->>> Saved combined mat file: %s\n', combinedMatFilePath);

quit(0);

