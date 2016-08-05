function Flds = determine_radar_fields( ATT );

% Determine which of the variables in ATT are 2-dimensional 
% radar fields, with coordinates of time and range.
% ATT includes all possible field names; ATT was formed with a call
% to get_hdf5_param_atts

% Written specifically for Matlab 7.12 (R2011a) and 
% CfRadial V1 draft 11 (document of 2011-01-18)
%     RA Rilling, NCAR  July 2011

test_flds = fields(ATT);
nparams = size( fields(ATT),1);

Flds = [];
for nn=1:nparams;
if( isfield(ATT.(test_flds{nn}), 'coordinates') && strmatch('time range', ATT.(test_flds{nn}).coordinates, 'exact' ) )
  Flds = [ Flds; cellstr(test_flds(nn)) ];
   end;
end;
