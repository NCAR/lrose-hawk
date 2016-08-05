function batch_view_repoh(today, ...
                          filenames, ...
                          snding_select, ...
                          avg_snding, ...
                          oneplot, ...
                          azi_sep, ...
                          azibin, ...
                          hgtbin, ...
                          hgt_lev, ...
                          show_scat, ...
                          repoh_mean, ...
                          gm3, ...
                          repoh_ascii_dir, ...
                          sounding_dir, ...
                          sounding_time)

  % snding_select: 'y' to plot soundings, 'n' for no.
  % avg_snding: Compute mean DOE sounding over the period
  %             for which you wish to view data?
  % oneplot: Plot everything on one plot? ('y' or 'n').
  % azi_sep: Separate by sectors (SW,NW,SE,NE)
  %          recall beam blockage to west requires only
  %          scans >= 2.5deg to be included.
  % azibin: Create analysis sectors by azimuth angle.
  %         Sectors must start at 0deg!
  % hgt_lev: What are sizes of height bins?
  % show_scat: Show a scatter plot?
  % repoh_mean: One big REPoH mean over the time period selected.
  %             Will do for each azimuth if azi_sep is 'y'
  % gm3: view in g m^-3 (y) or g kg^-1 (n)?
  
  %Date:  October 11, 2011
  %Author:  S. Powell, UW
  %Description:  Plot repoh retrievals against DOE Gan soundings,
  %              optionally by sector.  Requires driver_repoh.m to run.
  
  Rprime = (4/3)*6375;

if repoh_mean == 'y'
  oneplot = 'y';
else
if snding_select == 'n' %|| oneplot == 'n'
  avg_snding = 'n';  %Forces all sounding features off in case user forgot to set this.
end
%  show_scat = 'n';
end

%% Access REPoH files.

%Initialization of plot variables.
if repoh_mean == 'y'
  if azi_sep == 'y'
    ahgt_hold = nan(30,4,length(hgtbin)-1); humbin_hold = nan(30,4,length(hgtbin)-1);
    rho_hold = nan(30,4,length(hgtbin)-1);
    count = zeros(length(azibin)-1,length(hgtbin)-1);
  else
    ahgt_hold = nan(25,length(hgtbin)-1); humbin_hold = nan(25,length(hgtbin)-1);
    count = zeros(1,length(hgtbin)-1);
  end
else
  if azi_sep == 'y'
    humbin = nan(length(hgtbin)-1,size(filenames,2),length(azibin)-1);
    ahgt = humbin;
  else
    humbin = nan(length(hgtbin)-1,size(filenames,2));
    ahgt = humbin;
  end
end
scathum = nan(1,size(filenames,2)); scathgt = scathum; scatazi = scathum;

for i = 1:size(filenames,2)
  clear abshum, clear hgt, clear sounding, %clear humbin, clear ahgt
  fstring = cell2mat(filenames(i));
  fname = strcat([repoh_ascii_dir '/' fstring]);
  fprintf('DEBUG - batch_view_repoh: opening file: %s\n', fname);
  fid = fopen(fname);
    command = strcat('[AA,BB] = system(''wc -l');
    command = horzcat(command,' ',fname,''');');
    eval(command);
    numlines = sscanf(BB,'%d %*s');
    clear AA, clear BB;
    if numlines ~= 0
      for j = 1:numlines
        sounding(j,:) = fscanf(fid,'%f %f %f %f %f %f',6);
      end
      phi = sounding(:,1); %Zenith angle
      azi = sounding(:,2); %Azimuth angle
      Re = sounding(:,3); Rb = sounding(:,4); %Beginning and ending range;
      abshum = sounding(:,6);  %Humidity in g/m^3
      R = 0.5*(Rb + Re); %Range of midpoint of ray.
      %hgt(Rb < 1) = sqrt(R.^2 + Rprime.^2 + 2.*R.*Rprime.*sind(phi)) - Rprime;
      hgt1 = sqrt(Rb.^2 + Rprime.^2 + 2.*Rb.*Rprime.*sind(phi)) - Rprime;
      hgt2 = sqrt(Re.^2 + Rprime.^2 + 2.*Re.*Rprime.*sind(phi)) - Rprime;
      hgt = 0.5*(hgt1+hgt2);
      if repoh_mean == 'y'  %Might be able to do this for repoh_mean == 'y' with just scathum and scathgt in future version.
        if azi_sep == 'y'  
          %Separate by azimuth and take REPoH mean.
	  for k = 1:length(hgtbin) - 1
            for l = 1:length(azibin) - 1
              clear array;
              array = ((azi >= azibin(l)) .* (azi < azibin(l+1)) .* (hgt > (hgtbin(k))) .* (hgt <= hgtbin(k+1))) == 1;
              if numel(array) > 0 && max(array) == 1  %Require at least one element.
                humbin_hold(count(l,k)+1:count(l,k)+numel(abshum(array)),l,k) = abshum(array);
                ahgt_hold(count(l,k)+1:count(l,k)+numel(abshum(array)),l,k) = hgt(array);
                count(l,k) = count(l,k) + numel(abshum(array)); 
              end
            end
          end
        else %azi_sep == 'n'
          %Take REPoH mean but dont separate by azimuth.
          for k = 1:length(hgtbin) - 1
            clear array;
            array = (hgt > hgtbin(k)) .* (hgt <= hgtbin(k+1)) == 1;
            if numel(array) > 0 && max(array) == 1 
              humbin_hold(count(k)+1:count(k)+numel(abshum(array)),k) = abshum(array);
              ahgt_hold(count(k)+1:count(k)+numel(abshum(array)),k) = hgt(array);
              count(k) = count(k) + numel(abshum(array));
            end
          end
        end
      else %repoh_mean == 'n' 
        if azi_sep == 'n' %Dont take REPoH mean, and dont separate by azimuth.
          for k = 1:length(hgtbin) - 1
            clear array;
            array = (hgt > hgtbin(k)) .* (hgt <= hgtbin(k+1)) == 1;
            if (numel(abshum(array)) > 1)
              %Plot these.
              humbin(k,i) = mean(abshum(array));
              ahgt(k,i) = mean(hgt(array));
            else
              continue;
            end
          end
        else %azi_sep == 'y'
          for k = 1:length(hgtbin) - 1
            for l = 1:length(azibin)-1 
              clear array; 
              array = ((azi >= azibin(l)) .* (azi < azibin(l+1)) .* (hgt > (hgtbin(k))) .* (hgt <= hgtbin(k+1))) == 1;
              if (numel(abshum(array)) > 1)
                humbin(k,i,l) = mean(abshum(array));
                ahgt(k,i,l) = mean(hgt(array));
              end
            end
          end
        end
      end  %end repoh_mean.
    end    %end numlines
  fclose(fid);
  if numlines ~= 0 
    scathum(1:length(abshum),i) = abshum;
    scathgt(1:length(abshum),i) = hgt;
    scatazi(1:length(abshum),i) = azi;
  end
end

scathum(scathum == 0) = NaN;
scathgt(scathgt == 0) = NaN;
scatazi(scatazi == 0) = NaN;

%Estimate density..not taking directly from sounding yet.  May result in errors O(1 percent).
if gm3 == 'n'
  rho0 = 101000/287/(28+273);
  scatrho = rho0.*exp(-scathgt/8);
  scathum = scathum./scatrho;  %(in g kg^-1).
  rhobin_hold = rho0.*exp(-0.125.*ahgt_hold);
  humbin_hold = humbin_hold./rhobin_hold;
end

%% Adjust humbin and ahgt_bin.  May be set to median.

if repoh_mean == 'y' && azi_sep == 'y'
  %Plot these.
  humbin_hold(humbin_hold == 0) = NaN;
  ahgt_hold(ahgt_hold == 0) = NaN;
  humbin_mean = squeeze(nanmedian(humbin_hold))';
  ahgt_mean = squeeze(nanmedian(ahgt_hold))';
  ahgt_mean(count' < 10) = NaN;
%Below is code to plot the mode instead...
%  for k = 1:length(hgtbin) - 1
%    for l = 1:length(azibin)-1
%      clear H X mode_h
%      mode_h = scathum(((scatazi >= azibin(l)) .* (scatazi < azibin(l+1)) .* (scathgt > (hgtbin(k))) .* (scathgt <= hgtbin(k+1))) == 1);
%      [H,X] = hist(mode_h,modeset);
%      if numel(H(H==max(H))) > 1 && max(H) > 0
%        humbin_mean(k,l) = mean(X(H==max(H)));
%      elseif numel(H(H==max(H))) == 1
%        humbin_mean(k,l) = X(H==max(H));
%      else
%        humbin_mean(k,l) = NaN;
%      end
%    end
%  end
  humbin_mean(count' < 10) = NaN;
elseif repoh_mean == 'y' && azi_sep == 'n'
  humbin_hold(humbin_hold == 0) = NaN;
  ahgt_hold(ahgt_hold == 0) = NaN;
  humbin_mean = nanmedian(humbin_hold);
  ahgt_mean = nanmedian(ahgt_hold);
  ahgt_mean(count' < 10) = NaN;
%  for k = 1:length(hgtbin) - 1
%    clear H X mode_h
%    mode_h = scathum((scathgt > hgtbin(k)) .* (scathgt <= hgtbin(k+1)) == 1);
%    [H,X] = hist(mode_h,modeset);
%    if numel(H(H==max(H))) > 1 && max(H) > 0
%      humbin_mean(k) = mean(X(H==max(H)));
%    elseif numel(H(H==max(H))) == 1
%      humbin_mean(k) = X(H==max(H));
%    else
%      humbin_mean(k) = NaN;
%    end
%  end
  humbin_mean(count' < 10) = NaN;
end

if repoh_mean == 'y' 
  repoh_statistics;
end

%% Open one figure, or several?
if oneplot == 'y'
  figure(1), hold on
  ylabel('Height (km)','FontSize',14)
  if gm3 == 'n'
    xlabel('Specific Humidity (g kg^{-1})')
  else
    xlabel('Vapor Density (g m^{-3})')
  end
end

%% Now plot everything.
if repoh_mean == 'y'
  if azi_sep == 'n'
    if show_scat == 'y'
      scatter(reshape(scathum,numel(scathum),1),reshape(scathgt,numel(scathgt),1),'c+');
    end
    h = plot(humbin_mean(~isnan(humbin_mean)),ahgt_mean(~isnan(ahgt_mean)),'r','LineWidth',2);
    herrorbar(humbin_mean,ahgt_mean,E,'r');
  else %azi_sep == 'y'
    cols = [{'r+'},{'b+'},{'g+'},{'m+'},{'c+'},{'y+'}];
    pcols = [{'r'},{'b'},{'g'},{'m'},{'c'},{'y'}];
    for l = 1:length(azibin)-1
%      for k = 1:length(hgtbin)-1
%      end
      if show_scat == 'y'
        if azibin(l) <= 120 && azibin(l+1) > 120 
          scatter(scathum(((scatazi >= azibin(l)) .* (scatazi < azibin(l+1))) == 1 ), scathgt(((scatazi >= azibin(l)) .* (scatazi < azibin(l+1))) == 1 ), 100, cell2mat(cols(l)))
        else
          scatter(scathum(((scatazi >= azibin(l)) .* (scatazi < azibin(l+1))) == 1 ), scathgt(((scatazi >= azibin(l)) .* (scatazi < azibin(l+1))) == 1 ), cell2mat(cols(l)))
        end
      end
      if isnan(max(humbin_mean(:,l))) == 0
        h(l) = plot(humbin_mean(~isnan(humbin_mean(:,l)),l),ahgt_mean(~isnan(ahgt_mean(:,l)),l),cell2mat(pcols(l)),'LineWidth',2);
        herrorbar(humbin_mean(:,l),ahgt_mean(:,l),L(:,l),U(:,l),cell2mat(pcols(l))); 
      end
    end
  end
elseif repoh_mean == 'n'
  if oneplot == 'y'
    if azi_sep == 'n'
      if show_scat == 'y'
        scatter(reshape(scathum,numel(scathum),1),reshape(scathgt,numel(scathgt),1),'b');
      end
      plot(humbin(~isnan(humbin)),ahgt(~isnan(ahgt)),'r');
    else  %azi_sep == 'y'
      cols = [{'r+'},{'b+'},{'g+'},{'m+'},{'c+'},{'y+'}];
      pcols = [{'r'},{'b'},{'g'},{'m'},{'c'},{'y'}];
      for l = 1:length(azibin)-1
        %Don't take REPoH mean, but separate by azimuth.
        if show_scat == 'y'
          if azibin(l) <= 120 && azibin(l+1) > 120 
            scatter(scathum(((scatazi >= azibin(l)) .* (scatazi < azibin(l+1))) == 1 ), scathgt(((scatazi >= azibin(l)) .* (scatazi < azibin(l+1))) == 1 ), 100, cell2mat(cols(l)))
          else
            scatter(scathum(((scatazi >= azibin(l)) .* (scatazi < azibin(l+1))) == 1 ), scathgt(((scatazi >= azibin(l)) .* (scatazi < azibin(l+1))) == 1 ), cell2mat(cols(l)))
          end
        end
        for i = 1:size(humbin,2)
          plot(humbin(~isnan(humbin(:,i,l)),i,l),ahgt(~isnan(ahgt(:,i,l)),i,l),cell2mat(pcols(l)));
        end
      end
    end
  elseif oneplot == 'n'
    for i = 1:size(filenames,2)
      figure(i), hold on
      fstring = cell2mat(filenames(i));
      title(strcat([fstring(1:8) '-' fstring(10:15)]))
      if repoh_mean == 'n'
        if azi_sep == 'n'
          if show_scat == 'y'
            scatter(scathum(:,i),scathgt(:,i),'r');
          end
          plot(humbin(~isnan(humbin(:,i)),i),ahgt(~isnan(ahgt(:,i)),i),'r');
          axis([0 30 0 5]);
        else  %azi_sep == 'y'
          cols = [{'r+'},{'b+'},{'g+'},{'m+'},{'c+'},{'y+'}];
          pcols = [{'r'},{'b'},{'g'},{'m'},{'c'},{'y'}];
          for l = 1:length(azibin)-1
            clear plothum_hold, clear plothgt_hold
            %Don't take REPoH mean, but separate by azimuth.
            plothum_hold = scathum(:,i).*((scatazi(:,i) >= azibin(l)) .* (scatazi(:,i) < azibin(l+1)));  
            plothgt_hold = scathgt(:,i).*((scatazi(:,i) >= azibin(l)) .* (scatazi(:,i) < azibin(l+1)));  
            plothum(1:length(plothum_hold),i) = plothum_hold;
            plothgt(1:length(plothgt_hold),i) = plothgt_hold;
            plothum(plothum == 0) = NaN;
            plothgt(plothgt == 0) = NaN;
            if show_scat == 'y'
              if azibin(l) <= 120 && azibin(l+1) > 120 
                scatter(plothum(:,i),plothgt(:,i),100, cell2mat(cols(l)))
              else
                scatter(plothum(:,i),plothgt(:,i), cell2mat(cols(l)))
              end
            end
            plot(humbin(~isnan(humbin(:,i,l)),i,l),ahgt(~isnan(ahgt(:,i,l)),i,l),cell2mat(pcols(l)));
          end
        end
      end
    end
  end
end

%Set axis.
axis([0 30 0 5]), grid on

%% Let's intelligently access the sounding data. 

clear abshum ihgt rhgt hgt rho

if snding_select == 'y'
  sndname = [];

  if (length(sounding_time) > 0)

    sndFilePath = strcat([sounding_dir, today, '_', sounding_time, 'Z.mat']);
    fprintf('sounding file: %s\n', sndFilePath);
    sndname = [sndname; {sndFilePath}];

  else

  %First we'll make array to list which REPOH files to call.
  for i = 1:size(filenames,2)
    fstring = cell2mat(filenames(i));
    fprintf('-->> i, ascii filename: %d, %s\n', i, fstring);
    daystr = fstring(1:8);		%yyyymmdd
    hour = str2num(fstring(10:11)); 
    minute = str2num(fstring(12:13));	
    fprintf('     day, hour, minute: %s, %d, %d\n', daystr, hour, minute);
    if (hour < 3)
      sndFilePath = strcat([sounding_dir, today, '_02Z.mat']);
      fprintf('sounding file: %s\n', sndFilePath);
      sndname = [sndname; {sndFilePath}];
    elseif (hour < 6)
      sndFilePath = strcat([sounding_dir, today, '_05Z.mat']);
      fprintf('sounding file: %s\n', sndFilePath);
      sndname = [sndname; {sndFilePath}];
    elseif (hour < 9)
      sndFilePath = strcat([sounding_dir, today, '_08Z.mat']);
      fprintf('sounding file: %s\n', sndFilePath);
      sndname = [sndname; {sndFilePath}];
    elseif (hour < 12)
      sndFilePath = strcat([sounding_dir, today, '_11Z.mat']);
      fprintf('sounding file: %s\n', sndFilePath);
      sndname = [sndname; {sndFilePath}];
    elseif (hour < 15)
      sndFilePath = strcat([sounding_dir, today, '_14Z.mat']);
      fprintf('sounding file: %s\n', sndFilePath);
      sndname = [sndname; {sndFilePath}];
    elseif (hour < 18)
      sndFilePath = strcat([sounding_dir, today, '_17Z.mat']);
      fprintf('sounding file: %s\n', sndFilePath);
      sndname = [sndname; {sndFilePath}];
    elseif (hour < 21)
      sndFilePath = strcat([sounding_dir, today, '_20Z.mat']);
      fprintf('sounding file: %s\n', sndFilePath);
      sndname = [sndname; {sndFilePath}];
    else
      sndFilePath = strcat([sounding_dir, today, '_23Z.mat']);
      fprintf('sounding file: %s\n', sndFilePath);
      sndname = [sndname; {sndFilePath}];
    end
  end 

  end % if (length(sounding_time) > 0)

sndname2 = unique(sndname);  %For average sounding.

if oneplot == 'n'
  for i = 1:size(sndname,1);
    fstring = cell2mat(sndname(i,1));
    if exist(fstring) ~= 0
      load(fstring)
      figure(i)
      if gm3 == 'n'
        plot(abshum,hgt,'k','LineWidth',2)
      else
        plot(abshum.*rho,hgt,'k','LineWidth',2)
      end
      axis([0 30 0 5])
    end
  end
end
%elseif oneplot == 'y'
hold_hum = zeros(1,350);
hold_rho = zeros(1,350);
minsnd = 100*ones(1,350); maxsnd = zeros(1,350);
  for i = 1:size(sndname2,1);
    fstring = cell2mat(sndname2(i,1));
    if exist(fstring) ~= 0
      load(fstring)
      figure(1)
      if avg_snding == 'y'
        %Now we have to average the soundings together...
        rhgt = 0.1*round(hgt*10);
        ihgt = unique(rhgt);
        for k = 1:numel(ihgt)
          hold_hum(k) = hold_hum(k) + mean(abshum(rhgt == ihgt(k)));
          hold_rho(k) = hold_rho(k) + mean(rho(rhgt == ihgt(k)));
          sounding_statistics;
        end
      else
        if gm3 == 'n'
          plot(abshum,hgt,'k','LineWidth',2) 
        else
          plot(abshum.*rho,hgt,'k','LineWidth',2)
        end
      end
    end
  end
  if avg_snding == 'y'
    for i = size(sndname2,1):-1:1
      if exist(cell2mat(sndname2(i,:))) == 0
        sndname2(i,:) = [];  %Get rid of nonexistent sounding name, or the average won't come out correctly!
      end
    end
    avg_hum = hold_hum./size(sndname2,1);
    avg_rho = hold_rho./size(sndname2,1);
    if gm3 == 'n'
      plot(avg_hum,0:0.1:34.9,'k','LineWidth',2)
    else
      plot(avg_hum.*avg_rho,0:0.1:34.9,'k','LineWidth',2)
    end
    %Range of soundings
    minsnd(minsnd == 100) = NaN;
    maxsnd(maxsnd == 0) = NaN;
    if oneplot == 'n'
      for i = 1:size(sndname,1)
        figure(i), grid on 
        plot(minsnd,0:0.1:34.9,'k--','LineWidth',1)
        plot(maxsnd,0:0.1:34.9,'k--','LineWidth',1)
      end
    else
      plot(minsnd,0:0.1:34.9,'k--','LineWidth',1)
      plot(maxsnd,0:0.1:34.9,'k--','LineWidth',1)
    end
  end
  axis([0 30 0 5])
  if repoh_mean == 'y' && azi_sep == 'y'
    labels = [{'NE'},{'SE'},{'SW'},{'NW'}];
    if exist('h') ~= 0 
      legend(h(h~=0),labels(h~=0),'Location','NorthEast')
    end
  end
%end

end  %If snding_select == 'y'.

grid on
