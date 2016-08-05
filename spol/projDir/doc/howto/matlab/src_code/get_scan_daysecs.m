function secs = get_scan_daysecs( f_name )

% Pretty basic routine to read a CfRadial file that uses 
% HDF5 compression convention.  Extracts only the requested 
% variables. These variables are listed in the cell array Flds, 
% and the data are then packed into the structure "mydat" 
% for return.
% 
% Returns unscaled data values
%
% For antenna pointing, Flds might have the values:
%
Flds = {'time' 'time_coverage_start' 'time_coverage_end' };

% Written specifically for Matlab 7.12 (R2011a) and 
% CfRadial V1 draft 11 (document of 2011-01-18)
%     RAR  July 2011

% special note: there may be a "time_reference" attribute in some
% data sets.  If this variable exists, the "time" is computed relative
% to the time_reference, and not the time_coverage_start

f_name = deblank(f_name);
mydat = struct();

try 
  stime = h5read(f_name, ['/','time_coverage_start']);  % try reading any valid variable
  mydat = get_unscaled_hdf5_data(f_name,Flds);
catch err
  mydat = get_unscaled_nc_data(f_name, Flds);
end;

dstr = char(mydat.time_coverage_start);  % dstr may be a cell or string, depending upon input file
dstr = dstr';
dstr = [ regexprep(dstr,'[\-:A-Z]',' ') ];
tm = sscanf(dstr,'%d');

start_sec = tm(4) * 3600 + tm(5) * 60 + tm(6);

dstr = char(mydat.time_coverage_end);
dstr = dstr';
dstr = [ regexprep(dstr,'[\-:A-Z]',' ') ];
tm = sscanf(dstr,'%d');

end_sec = tm(4) * 3600 + tm(5) * 60 + tm(6);

% we are only working with single calendar days, and desire the
% seconds from the start of the day; in some cases the sweepfile
% will have started in the previous day.  Allow the start time to 
% then be negative.

if ( start_sec > end_sec )
   start_sec = start_sec - 86400;
end;

secs = mydat.time + start_sec;
