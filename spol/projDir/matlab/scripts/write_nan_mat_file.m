function write_nan_mat_file(matFileName, ...
                            matFilePath, ...
                            year, month, day, ...
                            hour, minute, second)
                            
% Date:  Dec 2011
% Author:  Mike Dixon, NCAR
% Description:  Writing a mat file filled with Nans

  ncFilePath = 'none';

  P = nan(300);
  T = nan(300);
  Td = nan(300);
  rh = nan(300);
  u = nan(300);
  v = nan(300);
  wind = nan(300);
  winddir = nan(300);
  hgt = nan(300);
  rho = nan(300);
  esat = nan(300);
  abshum = nan(300);

  fprintf('write_nan_mat_file: writing file: %s\n', matFilePath);

  save(matFilePath, ...
       'ncFilePath', 'matFilePath', ...
       'P', 'T', 'Td', 'rh', ...
       'u', 'v', 'wind','winddir', 'hgt', ...
       'rho', 'esat', 'abshum');

quit(0);

