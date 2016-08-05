function mydat = get_and_scale_hdf5_data( f_name, ATT, Flds )

% Pretty basic routine to read a CfRadial file that uses 
% HDF5 compression convention.  Extracts only the requested 
% variables. These variables are listed in the cell array Flds, 
% and the data are then packed into the structure "mydat" 
% for return.
% 
% Returns scaled data values as double precision variables.
% Substitutes NaN for missing data (data equal to FillValue).
%
% Requires knowledge of the parameter attributes, so the scale and bias
% information can be recovered.  
%
% For radar data, Flds might have the values:
%
% Flds = {'DBZ' 'DBMHC' 'VEL' 'VEL_F'};

% Written specifically for Matlab 7.12 (R2011a) and 
% CfRadial V1 draft 11 (document of 2011-01-18)
%     RA Rilling, NCAR  July 2011

  % Note: need to add code to check that a field actually exists in ATT

f_name = deblank(f_name);
%mydat = struct();

nlim = size(Flds);  nlim = nlim(2);

for nn=1:nlim
   data = h5read(f_name, ['/' Flds{nn}]);

   if( isfield(ATT.(Flds{nn}), 'FillValue'))
      missing_value = ATT.(Flds{nn}).FillValue;
% replace missing values with NaN; this also avoids the scaling of missing values
      clear ii
      ii=find(data == missing_value);
      data=double(data);         % this is required in order to set NaN
      data(ii) = NaN;
   end;

   if( isfield(ATT.(Flds{nn}), 'scale_factor'))
      scale_factor = ATT.(Flds{nn}).scale_factor;
      add_offset   = ATT.(Flds{nn}).add_offset;

      if (scale_factor ~= 0.0 | add_offset ~= 0.0)
         data=double(data);         % this is required in order to set NaN
         data = data*scale_factor + add_offset;
      end;
   end;

% determine if we have used variable gate numbers in the sweeps, and process accordingly.

%   if( (isfield(ATT,'n_gates_vary') && ~isempty(strmatch('true',ATT.n_gates_vary))) && ...
   if( isfield(ATT,'ray_n_gates')  && ...
       ( isfield(ATT.(Flds{nn}), 'coordinates') && ~isempty(strmatch('time range', ATT.(Flds{nn}).coordinates, 'exact' ))));
      G = get_unscaled_hdf5_data( f_name, {'ray_n_gates','ray_start_index', 'time'});
      Gmax = max(G.ray_n_gates);
      Gmin = min(G.ray_n_gates,1);
      if( Gmax == Gmin )
	 mydat.(Flds{nn}) = data;
      else
         nbeams = size(G.time,1);
         a(1:Gmax,1:nbeams) = NaN;
	 for jj=1:nbeams;
% note that the start index for the beams begins at zero. (C-style array index starts at 0)
            a(1:G.ray_n_gates(jj),jj) = data((G.ray_start_index(jj)+1):(G.ray_start_index(jj)+G.ray_n_gates(jj)));
         end;
         mydat.(Flds{nn}) = a;
      end;
   else
      mydat.(Flds{nn}) = data;
   end;

end;
