function f_name = get_sorted_file_list( my_date, dir_type, band, mytype );

% finds the full list of path/file names for all scan types under
% the directory structure used for S-Pol CfRadial data.  This is 
% necessary because scans are grouped first by type of data (moments, 
% covars, or whatever), then by s or x band, then by scan type.
%
% This routine is to be used to get a sorted list of files, that will then be
% used to open each file sequentially.
%
%  f_names = get_sorted_file_list('20110411', 'moments', 'sband');
% or
%  f_names = get_sorted_file_list('20110411', 'moments', 'sband', {'sur'; 'sec'});
%
% (it is a bit of a bad practice, but the last argument can be considered
% optional; this allows selection of only a few types of scans)

% be sure to set the "root directory" as a global in your calling routine:
global rt_direc;   % /export/d2/rilling/DYN_test/cfradial


stype = { 'rhi'; 'sec'; 'sur'; 'vert'};

if( exist('mytype'));
    stype = mytype;
end;

mydir = rt_direc;

if( isempty(regexp(mydir,'/$')) )
  mydir = [ mydir '/'];    % add trailing slash, if needed
end;

direc = [ mydir, dir_type, '/', band, '/' ];
f_name = [];
klow = 1;
fdat = {'1' '1'};

nlim = size(stype,1);
for nn=1:nlim;
    mydir = [ direc, char(stype(nn)), '/', my_date, '/'];
%  implicitly cover both options, dorade swp files and/or cfradial nc files:
    myfiles = [ dir(fullfile( mydir, 'cfrad*nc')) dir(fullfile( mydir, 'swp*')) ];
    klim = klow - 1 + size(myfiles,1);
    jj = 1;
    for kk=klow:klim;
       fdat(kk,1) = cellstr(mydir);
       fdat(kk,2) = cellstr(myfiles(jj).name);
       jj = jj + 1;
    end;
    klow = klow + size(myfiles,1);
end; 

fdat = sortrows( fdat, 2);
nlim = size(fdat,1);
for nn=1:nlim;
   tmp =  strcat(fdat(nn,1), fdat(nn,2));
   f_name = [f_name; tmp];
end;
