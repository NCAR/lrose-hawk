function mydat = get_unscaled_nc_data( f_name, Flds )

% Pretty basic routine to read a CfRadial file that does not use 
% HDF5 compression convention.  Extracts only the requested 
% variables. These variables are listed in the cell array Flds, 
% and the data are then packed into the structure "mydat" 
% for return.
% 
% Returns unscaled data values.  Does not account for case
% where n_gates_vary = 'true' (does repack truncated beams
% into uniform lengths)
%
% For antenna pointing, Flds might have the values:
%
% Flds = {'azimuth' 'elevation' 'fixed_angle' 'antenna_transition' 'sweep_mode' 'sweep_number' ...
%	  'sweep_start_ray_index' 'sweep_end_ray_index' 'time_coverage_start' 'time_coverage_end' };

% Written specifically for Matlab 7.12 (R2011a) and 
% CfRadial V1 draft 11 (document of 2011-01-18)
%     RAR  Aug 2011

f_name = deblank(f_name);
mydat = struct();

ncid = netcdf.open(f_name,'NC_NOWRITE');

nlim = size(Flds,2);

for nn=1:nlim
  varid = netcdf.inqVarID(ncid,Flds{nn});
  mydat.(Flds{nn}) =  netcdf.getVar(ncid,varid);
end;

netcdf.close(ncid);
