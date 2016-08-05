function day_sec = get_time_from_fname( f_name )

% Simple routine to return a time from a filename.
% Returns the number of seconds from the start of a day.
%

f_name = deblank(f_name);
junk = regexp(f_name,'/','split');
f_name = char(junk(size(junk,2)));

fparts = regexp(f_name,'\.','split');
dtype = char(fparts(1));

switch dtype
   case 'swp';
      dstr = char(fparts(2));
      tm = sscanf(dstr,'%03d%02d%02d%02d%02d%02d');
      day_sec = tm(4) * 3600 + tm(5) * 60 + tm(6);
   case 'cfrad';
      tstr = regexp(char(fparts(2)),'_','split');
      dstr = char(tstr(2));
      tm = sscanf(dstr,'%02d%02d%02d');
      day_sec = tm(1) * 3600 + tm(2) * 60 + tm(3);
   otherwise

end;
