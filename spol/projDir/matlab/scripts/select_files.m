function f_name = select_files(direc, filespec );

% example:
% f_name = select_files('/export/d2/rilling/DYN_test/cfradial/moments/sband','/cfrad*.nc');
%
% Allows selection of files from directory "direc", and returns file names 
% in string array f_name.   Handles situation where a single file is 
% treated as a string, but multiple files are cell arrays.
%
% "direc" is your starting directory name; "pathname" is the final directory 
% name, after you (may) finish chasing down sub-directories for your files.
%
%           RAR, NCAR June 2011

if( exist(direc) ~= 7)
   fprintf('\nRequested directory does not exist: %s\n\n',direc);
   fprintf('Setting directory to pwd.\n\n');
   fprintf('As an alternative, reset the directory name in your main calling routine.\n');
   direc = '.';
end;

if( isempty(regexp(direc,'/$')) )
  direc = [ direc '/'];    % add trailing slash, if needed
end;

[my_files, pathname, filterindex] = uigetfile( [direc '/' filespec], ...
            'Choose files (one or more).','MultiSelect', 'on');

f_name = '';
if( iscell( my_files));
   for nn=1:length(my_files);
      f_name = strvcat( f_name, [ pathname  my_files{nn} ]);
   end;
else;
   f_name = strvcat( f_name, [ pathname  my_files] );
end;


