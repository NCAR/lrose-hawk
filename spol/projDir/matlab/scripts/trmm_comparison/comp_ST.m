close all
clear all

fid = fopen('list_ST');
spol_files = [];
trmm_files = [];
while (1)
  [spol_file, count] = fscanf(fid, '%s', [1]);
  if (count ~= 1)
    break
  end
  [trmm_file, count] = fscanf(fid, '%s', [1]);
  spol_files = [spol_files; spol_file];
  trmm_files = [trmm_files; trmm_file];
end
start_x = 1;
x_lon = 71.75315;
y_lat = -1.979087;
xdbz = -10:60;
ydbz = -10:60;
[x_dbz y_dbz] = meshgrid(xdbz, ydbz);
xdata = [];
ydata = [];
mu_Fs = [];
std_Fs = [];
for s = 1: length(spol_files(:,1))
  maxdz = ncread(trmm_files(s,:), 'maxdz');
  lon   = ncread(trmm_files(s,:), 'longitude');
  lat   = ncread(trmm_files(s,:), 'latitude');
  alt   = ncread(trmm_files(s,:), 'altitude');
  DBZ_F = ncread(spol_files(s,:), 'DBZ_F');

  lon = double(lon-x_lon)*pi/90*6400/2.0;
  lat = double(lat-y_lat)*pi/90*6400/2.0;
  alt = double(alt);
  alt_spol = 0:.5:20-.5;
  [x_spol y_spol z_spol] = meshgrid(0:.5:300-.5, 0:.5:300-.5, alt_spol);
  [x_trmm y_trmm z_trmm] = meshgrid(lon, lat, alt);
  [x_grid y_grid z_grid] = meshgrid(lon, lat, alt_spol);
  [x2d y2d] = meshgrid(lon, lat);

  maxdz = double(maxdz);
  DBZ_F = permute(DBZ_F,   [2 1 3]);
  maxdz = permute(maxdz, [2 1 3]);
  maxdz(find(maxdz == 0 | maxdz == -888 | maxdz == -999)) = NaN;
  DBZ_interp = ...
      interp3(x_spol, y_spol, z_spol, DBZ_F(:,:,1:length(alt_spol)), ...
              x_grid, y_grid, z_grid);
  maxdz_interp = ...
      interp3(x_trmm, y_trmm, z_trmm, maxdz, x_grid, y_grid, z_grid);

  level =1:length(alt_spol);
%  idx = find(~isnan(DBZ_interp(:,:,level))&~isnan(maxdz_interp(:,:,level))& DBZ_interp(:,:,level) > start_x & DBZ_interp(:,:,level) < start_x +4);
  idx = find(~isnan(DBZ_interp(:,:,level))&~isnan(maxdz_interp(:,:,level)));
  xdata = [xdata; DBZ_interp(idx)];
  ydata = [ydata; maxdz_interp(idx)];
%  xdata = DBZ_interp(idx);
%  ydata = maxdz_interp(idx);
  if (length(xdata) == 0)
    continue
  end
  twoD_histo = hist2(xdata, ydata, xdbz, ydbz);
  highest = max(max(twoD_histo));
  if (highest < 10)
    continue
  end
  F = ydata-xdata;
  mu_F = mean(F);
  std_F = std(F);
  mu_Fs = [mu_Fs mu_F];
  std_Fs = [std_Fs std_F];
  wild_F = max(F) - min(F) + 5;
  histo_centers = mu_F-ceil(wild_F/2):.5:mu_F+ceil(wild_F/2);

  set(gcf,'Renderer','Zbuffer')
  subplot(1,2,1)
  hist(F,histo_centers);
  xlabel('TRMM dBZ - S-Pol dBZ (dB)')
  ylabel('Frequency (times)')
  title(['\mu = ', num2str(mu_F), 'dB, \sigma = ', num2str(std_F), 'dB'])
  subplot(1,2,2)
  plot3([-19-mu_F 60-mu_F] ,[-19 60], [highest highest], 'w-');
  text(0, mu_F, highest, num2str(mu_F), 'Color', 'w')
  hold on;
  surf(x_dbz, y_dbz, twoD_histo,'edgecolor', 'none');
  legend('white \mu intersection', 'Location','SouthEast')
  xlabel('dbz at S-Pol')
  ylabel('dbz at TRMM')
  axis([-9 60 0 60]); view(2); axis equal; colorbar;
  title(['alt: ', num2str(min(level)), '-', num2str(max(level)), 'km'])
  saveas(gcf, [num2str(min(level)/2-.5), '-', num2str(max(level)/2-.5), ...
              'km_', trmm_files(s,end-18:end-4), '.png'])
  hold off
  close all
end

figure(2)
plot(mu_Fs)
mu_mu_Fs = mean(mu_Fs);
xlabel('sample #')
ylabel('bias (dB)')
title(['max frequency > 10, alt: 0-40km, mean = ', num2str(mu_mu_Fs), 'dB'])
