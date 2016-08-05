function mydat = read_pointing_info_h5( f_name )

% Pretty basic routine to read just the antenna pointing info from
% a CfRadial file that uses HDF5 compression convention.
% Extracts only the known variables related to pointing.  These 
% variables are listed in the cell array Flds, and are then packed 
% into the structure "mydat" for return.

  % Written specifically for Matlab 7.12 (R2011a) and 
  % CfRadial V1 draft 11 (document of 2011-01-18)
  %     RAR  July 2011

f_name = deblank(f_name);
mydat = struct();
Flds = {'azimuth' 'elevation' 'fixed_angle' 'antenna_transition' 'sweep_mode' 'sweep_number' ...
    'sweep_start_ray_index' 'sweep_end_ray_index' 'time' 'time_coverage_start' 'time_coverage_end' };

nlim = size(Flds);  nlim = nlim(2);

for nn=1:nlim
  mydat.(Flds{nn}) =  h5read(f_name, ['/' Flds{nn}]);
end
