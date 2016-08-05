function secs = get_cfradnc_daysecs( mydat )

% Inspects the data structure of a CfRadial data sets, and 
% re-arranges to provide the seconds from the start of the day
% 
% Returns unscaled data values
%
Flds = {'time' 'time_coverage_start' 'time_coverage_end' };

% Written specifically for Matlab 7.12 (R2011a) and 
% CfRadial V1 draft 11 (document of 2011-01-18)
%     RAR  July 2011

% special note: there may be a "time_reference" attribute in some
% data sets.  If this variable exists, the "time" is computed relative
% to the time_reference, and not the time_coverage_start

dstr = [ char(mydat.time_coverage_start(:))' ];
dstr = [ regexprep(dstr,'[\-:A-Z]',' ') ];
tm = sscanf(dstr,'%d');

start_sec = tm(4) * 3600 + tm(5) * 60 + tm(6);

dstr = [ char(mydat.time_coverage_end(:))' ];
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
