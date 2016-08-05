function PID_fraction_batch(myDate);
%  Start-up routine for particle ID sums

%  Computes the volume-weighted fraction of the different PID classifications.
%  Does this on a radar scan volume-by-volume basis.  Only SUR scans should be
%  used for this operation.
%
%  This routine computes a pseudo volume for every radar gate, using the depth of the gate
%  and the beamwidth (assumed to be 1-deg), using a rectangular approximation.  In this scheme,
%  gates near the radar carry very little weight, while those at extreme range are much larger,
% and a given PID is weighted over that larger volume.
%  
%  All work is done in radar space.  Note that it was not felt that gridding of PID would be a
%  reliable process, and that the calculations presented here are more physically correct.
%
%  In a practical sense, you require a very complete volume scan (good elevation spacing to a 
%  high tilt angle) to adequately cover a volume.  You should ignore scans with only a few tilts.
%  There will always be a "cone of silence" over the radar.
%
%  The S-Pol test pulse is explicitly removed, as well as data above the troposphere.
%  
%  Note that your largest particle fraction will almost always be for the type "unclassified."
%  
%  This routine runs using S-Pol cfradial format data.  The data are under the "partrain" path.
%  It requires about 3 wallclock seconds to process each radar volume (6 tilts, 360-beams per tilt).
%  Output is to both the matlab control window (detailed diagnostics), and a summary output to a 
%  data file.  The data file should be hand-edited to remove bad volumes (criteria: transmitter off;
%  multiple NaN values; too few tilts).
%
%  A companion routine (PID_read_plot) is used to plot a single bar graph summary for the data file.
%
%  Written in the field during DYNAMO, R. Rilling  NCAR/EOL   9/2011
%
% Particle types are:
%   1   CL   Cloud particles
%   2   Drz  Drizzle
%   3   Lr   Light rain
%   4   Mr   Moderate rain
%   5   Hr   Heavy rain
%   6   Ha   Hail
%   7   Rh   Rain/hail mix
%   8   Gsh  Graupel/small hail
%   9   GRR  Graupel/rain mix
%  10   Ds   Dry snow
%  11   Ws   Wet snow
%  12   Ic   Oriented ice crystals (horizontal)
%  13   Iic  Irregular ice crystals
%  14   Sld  Super-coolded liquid water drops (cloud drop sized)
%  15   Bgs  Insects
%  16   Brd  2nd trip
%  17   Gcl  Ground clutter
%  18   Unc  not-a-number (unclassified, for this code, only)
%  19   [ ]  not labeled.  These gates are test pulse, or above the tropopause and are not counted.

% Note that many PID gates are flagged with a missing_value, indicating low SNR or other threshold criteria.
% These will be reclassified to category 18.  (Note: I have never found any values of 18 in the original 
% PID data set)

direc = '/scr/pgen2/cfradial/partrain/sband/sur';
set(0,'DefaultTextInterpreter','none');

global rt_direc;
rt_direc = '/scr/pgen2/cfradial';

ptype = {'Cl' 'Drz' 'Lr' 'Mr' 'Hr' 'Ha' 'Rh' 'Gsh' 'GRR' 'Ds' 'Ws' 'Ic' 'Iic' 'Sld' 'Bgs' '2nd' 'Gcl' 'Unc'};
gatewidth = .150;   % assumed constant for all DYNAMO
trop_height = 17.0;  % approximated troposphere height 

% determine if we are running in batch mode.  (this does not always work!)
% If we are in batch mode, output is restricted, and output files go in another location
% if we are running in batch, we mostly set the display to something other than :0

batch = false;
interactive_tst =  get(0,'ScreenDepth');
displaynum = getenv('DISPLAY');

if((numel(interactive_tst) == 1 && interactive_tst(1) == 0) || ~strncmp(displaynum,':0',2 ));
   batch = true;
end;

% set a beamwidth weighting function; assume a 1-deg beam, h and v.  This is an approximation.

sinsq = sin(1.0 * pi/180);
sinsq = sinsq * sinsq * gatewidth;  % beamwidth by beamwidth by voxel (or gate) depth


if( batch );
   ofile = ['/home/operator/projDir/data/matlab/analysis/PID_summary.' myDate '.out' ];
   wmode = 'w';
   f_name = get_sorted_file_list(myDate,'partrain','sband',{'sur'});
else;
   % ask for an output filename.  this file will either be new, or opened to append

   reply = input('Provide a name for the summary output file: ', 's');
   if isempty(reply)
      reply = 'PID_sum.out';
   end;
   ofile = reply;

   if( exist(ofile) == 2)
      reply = input('    Append to this file?  (Y/N): ', 's');
      if isempty(reply)
         wmode = 'w';
      else;
         if( strcmpi(reply,'y'));
            wmode = 'a';
         else;
            wmode = 'w';
         end;
      end;
   else;
      wmode = 'w';
   end;
   f_name = select_files(direc, '/cfrad*.nc');
end;

fout = fopen(ofile,wmode);
fprintf(fout,'%%  Volume Start      ');
for ii=1:numel(ptype);
    fprintf(fout,'%5s ',char(ptype{ii}));
end;
fprintf(fout,'\n');

% make the assumption that Attributes will not change over the next
% few volumes (this is a serious assumption!)

[ ATT ] = get_hdf5_param_atts( char(f_name(1,:)) );
Flds = determine_radar_fields( ATT );

sFlds = {'PID'};

klim = size(f_name,1);
for kk=1:klim;
   SWP = get_and_scale_hdf5_data( char(deblank(f_name(kk,:))), ATT, [sFlds { ...
       'time_coverage_end' 'time_coverage_start' 'time' 'range' ...
       'sweep_number' 'fixed_angle' 'azimuth' 'elevation' 'antenna_transition'}]);

% we do not much care about azimuth and elevation, but we want to make sure
% that we do not include transition beams.  Filter out the transition beams.

   nbeams = size(SWP.time,1);
   ngates = size(SWP.range,1);
   tx_ers = find(SWP.antenna_transition == 1);
   blim = nbeams - size(tx_ers,1);

% initialize an empty array to hold non-transition beam PID.  pid is smaller than SWP.PID
   pid = [];
   pid(1:size(SWP.PID,1),1:blim) = NaN;  % protect against bad range vector size

% compute range and beamwidth weighting factors; rwgt is invariant throughout 
% the scan volume

   rwgt = ((SWP.range/1000).^2) * sinsq;   % sinsq includes the gate depth
% there is a glitch in some of the cfrad volumes.  Sometimes, the total number of gates
% for a beam is greater than the size of the range vector.  Kludge a fix for this.
% (Mike Dixon has this problem on his "to do" list, 20110927)
% This kludge will still not catch all of the problems.  The size of SPW.PID can be in error.
   if( size(SWP.PID,1) > ngates);
      rwgt(ngates+1:size(SWP.PID,1)) = 0;
   end;

% eliminate transition beams or neg elevation, and clip test pulse and data above tropopause
   jj = 1;
   for nn=1:nbeams;
      if( SWP.antenna_transition(nn) == 1 || SWP.elevation(nn) < 0.0 ) 
%        skip the transition beam
         continue; 
      end;
      pid(:,jj) = SWP.PID(:,nn);
% chop out the test pulse (based upon known gate numbers)
      pid((ngates-12):ngates,jj) = 19;  % set value to edited-out classification
% eliminate data above the tropopause (assumed about 17 km)
      rmax = trop_height * 1000 / (sin(SWP.elevation(nn) * pi/180));
      mgate = round((rmax/150 + .499));
      mgate = min([mgate ngates]);
      pid(mgate:ngates,jj) = 19;   % ngates is a test pulse gate, anyhow.
      jj = jj + 1;
   end;

   pid = round(pid);   % because of data scaling, SWP.PID was not necessarily an integer
% a bit dangerous, but works for this code: reset NaNs to classification 18
   a = find(isnan(pid));
   pid(a) = 18;

   pbeams = size(pid,2);
   tgates = 0;
   for jj=1:18;
      ptmp = reshape(pid,numel(pid),1);
      A = find(ptmp ~= (jj));
      B = find(ptmp == (jj));
      ptmp(A) = NaN;
      ptmp = reshape(ptmp,ngates,pbeams);
      for ii=1:pbeams;
          ptmp(:,ii) = (~isnan(ptmp(:,ii))) .* rwgt(:);  % range weight according to incidence of occurance
      end;
      totgate(jj) = numel(B);
      tot(jj) = sum(nansum(ptmp));
   end;

   volsize = sum(tot);
   if( ~batch );
      fprintf('\nStart time %s   End Time %s\n\n', ...
          deblank([SWP.time_coverage_start{:}]),deblank([SWP.time_coverage_end{:}]));
   end;
   for jj=1:18;
      percnt(jj) = 100 * (tot(jj)/volsize);
      if( ~batch );
         fprintf('%3s, gate_tot = %10d   voltot = %10.0f   percent = %5.2f\n', ...
              ptype{jj}, totgate(jj), tot(jj), percnt(jj));
      end;
   end;
   if( ~batch );
      fprintf('\nrelative volume of all used gates: %10.0f (proportional to cubic km)\n', volsize);
      fprintf('number of PID gates used %d (of a possible total of %d)\n\n',...
           sum(totgate), numel(ptmp));
   end;
   vals = sprintf('%6.2f',percnt);
   angs = sprintf('%5.1f',SWP.fixed_angle);
   fprintf(fout, '%s %s angs:%s vol:%8.0f\n',deblank([SWP.time_coverage_end{:}]),vals,angs,volsize);
end;
fclose( fout );

if( batch )
   exit;
end;
