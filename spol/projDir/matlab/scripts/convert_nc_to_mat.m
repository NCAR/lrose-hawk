function convert_nc_to_mat(ncFilePath, matFilePath)

% Date:  Dec 2011
% Author:  Mike Dixon, NCAR
% Description:  Convert a sounding netCDF file to a mat file

  Rstar = 287;
  maxheight = 20;

% load up variables from NC file

  fprintf('convert_nc_to_mat: reading file: %s\n', ncFilePath);

  ncid = netcdf.open(ncFilePath,'NC_NOWRITE');

  [ndims,nvars,ngatts,unlimdimid] = netcdf.inq(ncid);
  for ii = 1:nvars-1
    [varname,xtype,dimids,natts] = netcdf.inqVar(ncid,ii);
    if (strcmp(varname, 'pres'))
      P = netcdf.getVar(ncid,ii);
      fprintf('Found var pres, id: %d\n', ii);
    elseif (strcmp(varname, 'tdry'))
      T = netcdf.getVar(ncid,ii);
      fprintf('Found var tdry, id: %d\n', ii);
    elseif (strcmp(varname, 'dp'))
      Td = netcdf.getVar(ncid,ii);
      fprintf('Found var dp, id: %d\n', ii);
    elseif (strcmp(varname, 'rh'))
      rh = netcdf.getVar(ncid,ii);
      fprintf('Found var rh, id: %d\n', ii);
    elseif (strcmp(varname, 'u_wind'))
      u = netcdf.getVar(ncid,ii);
      fprintf('Found var u_wind, id: %d\n', ii);
    elseif (strcmp(varname, 'v_wind'))
      v = netcdf.getVar(ncid,ii);
      fprintf('Found var v_wind, id: %d\n', ii);
    elseif (strcmp(varname, 'wspd'))
      wind = netcdf.getVar(ncid,ii);
      fprintf('Found var wspd, id: %d\n', ii);
    elseif (strcmp(varname, 'wdir'))
      winddir = netcdf.getVar(ncid,ii);
      fprintf('Found var wdir, id: %d\n', ii);
    elseif (strcmp(varname, 'deg'))
      winddir = netcdf.getVar(ncid,ii);
      fprintf('Found var deg, id: %d\n', ii);
    elseif (strcmp(varname, 'alt'))
      hgt = netcdf.getVar(ncid,ii);
      fprintf('Found var alt, id: %d\n', ii);
    end
  end

  netcdf.close(ncid);

% check that the fields exist

  if (exist('P') == 0)
    fprintf('ERROR - var pres not found\n');
    return;
  end

  if (exist('T') == 0)
    fprintf('ERROR - var tdry not found\n');
    return;
  end

  if (exist('Td') == 0)
    fprintf('ERROR - var dp not found\n');
    return;
  end

  if (exist('rh') == 0)
    fprintf('ERROR - var rh not found\n');
    return;
  end

  if (exist('u') == 0)
    fprintf('ERROR - var u_wind not found\n');
    return;
  end

  if (exist('v') == 0)
    fprintf('ERROR - var v_wind not found\n');
    return;
  end

  if (exist('wind') == 0)
    fprintf('ERROR - var wspd not found\n');
    return;
  end

  if (exist('winddir') == 0)
    fprintf('ERROR - var wdir not found\n');
    return;
  end

  if (exist('hgt') == 0)
    fprintf('ERROR - var alt not found\n');
    return;
  end

% Set missing to NaNs.

  P(P<0) = NaN;
  T(T<-200) = NaN;
  Td(Td<-200) = NaN;
  rh(rh<0) = NaN;
  u(u<-100) = NaN;
  u(u>100) = NaN;
  v(v<-100) = NaN;
  v(v>100) = NaN;
  hgt(hgt==-999) = NaN;
  hgt = 0.001*hgt;  %Convert to km.
  rho = 100*P./(Rstar.*(T+273.15)); %(kg m^-3) 

  esat = nan(length(T),1);
  esat(T>0,1) = 0.6108*exp((17.27*T(T>0))./(T(T>0)+237.3));       % Over water
  esat(T<=0,1) = 0.6108*exp((21.875*T(T<=0))./(T(T<=0)+265.5));   % Over ice
  % Convert relative humidity to absolute humidity in g kg^-1.
  e = 0.01*esat.*rh;  %Multiply sat vapor pressure by RH.
  abshum = ((2165.*e)./(T+273.16))./rho; %in g kg^-1.

  fprintf('convert_nc_to_mat: writing file: %s\n', matFilePath);

  save(matFilePath, ...
       'ncFilePath', 'matFilePath', ...
       'P', 'T', 'Td', 'rh', ...
       'u', 'v', 'wind','winddir', 'hgt', ...
       'rho', 'esat', 'abshum');

quit(0);

