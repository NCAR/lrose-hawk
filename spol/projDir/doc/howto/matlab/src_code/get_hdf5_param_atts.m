function [ ATT ] = get_hdf5_param_atts( f_name )
%
% recover/restructure all attributes for all parameters in 
% a CfRadial data set.
%
% There is an implied assumption that all attributes can be 
% recovered at the same "depth" into the myinfo structure.
%
% Written specifically for Matlab 7.12 (R2011a) and 
% CfRadial V1 draft 11 (document of 2011-01-18)
%     RA Rilling, NCAR  July 2011
%
ATT = struct();
f_name = deblank(f_name);

myinfo = h5info(f_name, '/');   % this command requires a lot of clock time!

nparams = size( myinfo.Datasets, 1);

for nn=1:nparams;
   natts = size(myinfo.Datasets(nn).Attributes, 1);
   tp_name = myinfo.Datasets(nn).Name;
   for jj=1:natts;
      t_attname = myinfo.Datasets(nn).Attributes(jj).Name;
      t_attname = regexprep( deblank(t_attname ), '^_', '');
      ATT.(tp_name).(t_attname) = myinfo.Datasets(nn).Attributes(jj).Value;
   end;
end;
