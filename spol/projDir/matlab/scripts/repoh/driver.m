%Date: October 2, 2011
%Author: S. Powell, UW
%Description:  Driver program for reading in Gan soundings, converting to specific humidity and saving to a cumulative matfile.

clear all; close all; clc;

system('ls -C1 ~/projDir/data/matlab/sounding/*.raw > ~/projDir/data/matlab/files.driver');

[A,B] = system('wc -l ~/projDir/data/matlab/files.driver');
numfiles = sscanf(B,'%d %*s');

fprintf('numfiles: %d\n', numfiles);

fid2 = fopen('~/projDir/data/matlab/files.driver');
for j = 1:numfiles
  fname = fscanf(fid2,'%s',1);
  fprintf('-->>working on file: %s\n', fname);
  %fscanf(fid2,'%c',1);
  read_in_gan;
end
