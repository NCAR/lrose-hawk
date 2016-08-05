% simplist example of getting data from cfradial files on the S-Pol net
%   (DYNAMO, Oct 2011)
%
%  sequence:
%
%     -- set a directory
%     -- get a list of desired filenames
%     -- determine the Attributes of the first CfRadial data set
%            (assume major attributes do not change for this process)
%     -- determine which fields are valid radar-space fields
%     -- select desired radar fields
%     -- get the selected data fields, and some additional housekeeping from a SWP
%     -- repeat, as desired or required

direc = '/scr/pgen2/cfradial/partrain/sband';
% other directory examples::
%  direc = '/scr/pgen2/cfradial/covar/sband/sur';
%  direc = '/scr/pgen2/cfradial/covar/xband/sur';
%  direc = '/scr/pgen2/cfradial/moments/sband/sur';
%  direc = '/scr/pgen2/cfradial/moments/xband/sur';

f_name = select_files(direc, '/cfrad*.nc');  % returns one, or multiple file names

% determining the Attributes is a slow process, and seems to be due
% to the use of h5info (mathworks routine)

[ ATT ] = get_hdf5_param_atts( f_name(1,:) );
Flds = determine_radar_fields( ATT );
sFlds = select_params(Flds);

% recover certain specified fields, including the selected radar fields
% (kk is the file number in the list recovered from select_files)

for kk=1:size(f_name,1);

   SWP = get_and_scale_hdf5_data(deblank(f_name(kk,:)), ATT, [sFlds { ...
       'time_coverage_end' 'time_coverage_start' 'time' 'range' ...
       'sweep_number' 'fixed_angle' 'azimuth' 'elevation' 'antenna_transition'}]);

end;

% to get all fields, do the following -- note the ' after the fields(ATT)'

   SWP = get_and_scale_hdf5_data(deblank(f_name(kk,:)), ATT, [ fields(ATT)' ]);
