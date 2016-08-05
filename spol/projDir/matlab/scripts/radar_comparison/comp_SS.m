clear all
close all
domain = 0; % -1 for SE, 1 for NE, 0 for E, other for all
km = 7:.5:10;
fid = fopen('list2');
sband_files = [];
smartr_files = [];
while(1)
  [sband, count] = fscanf(fid,'%s',1);
  if (count == 0)
    break
  end
   [smartr, count] = fscanf(fid,'%s',1);
  sband_files = [sband_files; sband];
  smartr_files = [smartr_files; smartr];
end
fclose(fid);
mu_Fs = [];
std_Fs = [];
mu_F_1s = [];
mu_F_2s = [];
for s = 1: length(sband_files(:,1))
  x = now;
  disp(now-x)
  sband_nc  = sband_files(s,:);
  smartr_nc = smartr_files(s,:);
  sband_dbz  = ncread(sband_nc, 'DBZ_F');
  smartr_dbz = ncread(smartr_nc, 'DBZ');
  f1         = ncread(smartr_nc, 'WIDTH');
  f2         = ncread(smartr_nc, 'VEL');
  base_smartr= ncread(smartr_nc, 'base_time');
  base_sband = ncread(sband_nc, 'base_time');
  date_str  = datestr(datenum([1970 01 01 00 00 00]) +...
                      double(base_sband)/86400);
  date_str_r= datestr(datenum([1970 01 01 00 00 00]) +...
                      double(base_smartr)/86400);

  xgrid_offset = 2;
  ygrid_offset = 5;
  if (domain == -1) %SE
    x_idx = 270:600-xgrid_offset;
    y_idx = 1:300-ygrid_offset;
  elseif (domain == 1) %NE
    x_idx = 270:600-xgrid_offset;
    y_idx = 300:600-ygrid_offset;
  elseif (domain == 0) %E
    x_idx = 270:600-xgrid_offset;
    y_idx = 1:600-ygrid_offset;
  else
    x_idx = 1:600-xgrid_offset;
    y_idx = 1:600-ygrid_offset;
  end
% height change
  sband_dbz  =  sband_dbz(x_idx,y_idx+ygrid_offset,km*2+1);
  smartr_dbz = smartr_dbz(x_idx+xgrid_offset,y_idx,km*2-1);
  f1         =         f1(x_idx+xgrid_offset,y_idx,km*2-1);
  f2         =         f2(x_idx+xgrid_offset,y_idx,km*2-1);

  idx = find(~isnan(f1) & ~isnan(f2) & ~isnan(sband_dbz));
  xdata_spol   =  sband_dbz(idx);
  ydata_smartr = smartr_dbz(idx);

  start_x = -39; end_x = start_x + 99; % dB
  [xgrid ygrid] = meshgrid(start_x-.5:1:end_x-.5, -19-.5:1:60-.5);

  idx = find(xdata_spol > start_x-.5 & xdata_spol < end_x+.5);
  xdata_spol = xdata_spol(idx);
  ydata_smartr = ydata_smartr(idx);

  if (isempty(xdata_spol))
    continue
  end
  twoD_histo = hist2(xdata_spol, ydata_smartr, xgrid(1,:),ygrid(:,1)');
  highest = max(max(twoD_histo));
  twoD_histo(find(twoD_histo < 1/3*highest)) = 0;

  ydata = [];
  xdata = [];
  disp(now-x)
  for u = 1:length(twoD_histo(1,:))
    for v = 1:length(twoD_histo(:,1))
      xdata = [xdata; xgrid(1,u)*ones([twoD_histo(v,u),1])];
      ydata = [ydata; ygrid(v,1)*ones([twoD_histo(v,u),1])];
    end
  end
  disp(now-x)
  F = ydata - xdata;
  mu_F = mean(F);
  std_F = std(F);
  wild_F = max(F) - min(F) + 5;
  histo_centers = mu_F-ceil(wild_F/2):.5:mu_F+ceil(wild_F/2);
  if (isempty(F))
    continue
  end
     

  idx_1 = find(abs(ydata - xdata - mu_F) < std_F);
  idx_2 = find(abs(ydata - xdata - mu_F) < 2*std_F);
  F_1 = ydata(idx_1) - xdata(idx_1);
  F_2 = ydata(idx_2) - xdata(idx_2);
   mu_F_1 = mean(F_1);
  std_F_1 =  std(F_1);
   mu_F_2 = mean(F_2);
  std_F_2 =  std(F_2);
  pxy = polyfit(xdata, ydata, 1);
  pyx = polyfit(ydata, xdata, 1);

  figure('Position',[1 1 1200 600])
  set(gcf,'Renderer','Zbuffer')
  subplot(1,2,1)
  hist(F,histo_centers);hold on
  hist(F_2,histo_centers);
  hist(F_1,histo_centers);
  xlabel('SMART-R dBZ - S-Pol dBZ (dB)')
  ylabel('Frequency (times)')
  title(['\sigma = ', num2str(std_F), ', \mu = ', num2str(mu_F), ...
      ' \mu_{1d} = ', num2str(mu_F_1),', \mu_{2d} = ', num2str(mu_F_2)])
  h = findobj(gca,'Type','patch');
  set(h(1),'FaceColor','b','EdgeColor','w')
  set(h(2),'FaceColor','g','EdgeColor','w')
  set(h(3),'FaceColor','r','EdgeColor','w')
  legend('All', 'In 2\sigma', 'In 1\sigma')

  %  numbg = round((highest-200)*2/3);
%      if (twoD_histo(s,t) < numbg)
%        continue
%      end

  set(gcf,'Renderer','Zbuffer')
  subplot(1,2,2)
  plot3(...
 [-19-(mu_F+std_F) 60-(mu_F+std_F)] ,[-19 60], [highest highest], 'b-',...
 [-19-(mu_F+2*std_F) 60-(mu_F+2*std_F)] ,[-19 60], [highest highest], 'r-',...
 [-19-mu_F 60-mu_F] ,[-19 60], [highest highest], 'w-',...
...
 [-39 60] ,[-39*pxy(1)+pxy(2) 60*pxy(1)+pxy(2)], [highest highest], 'y-', ...
...
 [-19-(mu_F-std_F) 60-(mu_F-std_F)] ,[-19 60], [highest highest], 'b-',...
 [-19-(mu_F-2*std_F) 60-(mu_F-2*std_F)] ,[-19 60], [highest highest], 'r-')...
% [-39 60] ,[-39*pxy(1)+pxy(2) 60*pxy(1)+pxy(2)], [highest highest], 'b-', ...
% [-19*pyx(1)+pyx(2) 60*pyx(1)+pyx(2)], [-19 60], [highest highest], 'r-', ...
  hold on;
  surf(xgrid, ygrid, twoD_histo,'edgecolor','none'); view(2);
  legend('one \sigma', 'two \sigma', '\mu intersection', ...
         ['x to y, a=', num2str(pxy(1)), ',b=', num2str(pxy(2))],...
          'Location','SouthEast')
  xlabel('dbz at S-Pol')
  ylabel('dbz at SMART-R')
  axis([-39 60 -19 60])
  axis equal
%  title(['# of point >= ', num2str(numbg)])
  title([date_str, ' ', date_str_r])
  colormap('jet'); colorbar
  text(0, mu_F, highest, num2str(mu_F), 'Color', 'w')

  temp_filename = dir(sband_files(s,:));
  F = getframe(gcf);
  imwrite(F.cdata, [temp_filename.name(1:end-3), '.png'], 'png');
  mu_Fs = [mu_Fs; mu_F];
  std_Fs = [std_Fs; std_F];
  mu_F_1s = [mu_F_1s; mu_F_1];
  mu_F_2s = [mu_F_2s; mu_F_2];
  close all
end
