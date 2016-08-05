function make_mat_files_gan(repoh_dir)

%Date: October 2, 2011
%Author: S. Powell, UW
%Description:  Driver program for reading in Gan soundings, converting to specific humidity and saving to a cumulative matfile.

% create list of files

sounding_dir = strcat([ repoh_dir, '/sounding' ]);
filelist = strcat([ repoh_dir, '/files.make_mat' ]);
command = strcat(['ls -C1 ' sounding_dir '/*.raw > ' filelist]);
fprintf('Running command: %s\n', command);
system(command);

command = strcat(['wc -l ' filelist]);
fprintf('Running command: %s\n', command);
[A,B] = system(command);
numfiles = sscanf(B,'%d %*s');

fprintf('numfiles: %d\n', numfiles);

fid2 = fopen(filelist);
for j = 1:numfiles
  fname = fscanf(fid2,'%s',1);
  fprintf('-->>working on file: %s\n', fname);
  %fscanf(fid2,'%c',1);
  read_in_gan(fname)
end

quit(0)
