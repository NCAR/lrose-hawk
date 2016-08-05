function plotstat = plot_pointing_info( mydat, dispo, figs_dir );

% plots S-Pol az/el/beam number in 5 different ways.
%
% mydat    structure that contains angle and beam information values
%          in mydat are re-assigned to local variables, as necessary.
%
% dispo    states desired disposition of az/el/beam plots.
%          'save' is the only valid value of dispo that will take
%          any action.
%
% figs_dir subdirectory for storage of saved figures
%
% az and el are, ideally, azimuth and elevation arrays over a whole scan volume.
% fa is a short list of unique fixed angles (perhaps 5 to 10 angles)
% scan type is a number from 0 to 8, using the Dick Oye coding for scan type.
% start and end of period covered is also required for plot title purposes.
%
%                     RAR  26-Jun-2011
% 
% NOTE: SINCE SPOL DOES INDEXED BEAMS, WE REALLY NEED TO LOOK AT DAZ AND DEL VS TIME!
%   (this mod needs to be added)

set(0,'DefaultTextInterpreter','none');

% persistent xscan edges;

xscan = [ {'CAL'},{'PPI'},{'COP'},{'RHI'},{'VER'},{'TAR'},{'CAL'},{'IDL'},{'SUR'}];
smode = { 'sector' 'coplane' 'rhi' 'vertical_pointing' 'pointing' 'calibration' 'idle' ...
	  'azimuth_surveillance' 'elevation_surveillance' 'sunscan' 'manual_ppi' 'manual_rhi' };
edges = 0:360;    % array to use in histogram determination of scan center

% use a positional match to the scan types in smode, and find the stype number for this volume:

tststr = deblank(['^' mydat.sweep_mode{:,1}]);
nlim = size(smode); nlim = nlim(2);
stype = -1;
for nn=1:nlim;
   if( regexp(smode{nn}, tststr) )
      stype = nn;
   end;
end;

if( ~exist('dispo'))   % if dispo = 'save', plots are saved in subdir "figs"
    dispo = 'no';
end;

if( exist('figs_dir'))   % plots are saved in subdir "figs"
    figd = figs_dir;
else
    figd = 'figs';
end;
if( exist(figd) ~= 7 ) && ( strcmp(dispo,'save') )
    mkdir(figd);
end;

az = mydat.azimuth;
el = mydat.elevation;
txf = mydat.antenna_transition;
fa  = mydat.fixed_angle;

mytitle = [ 'S-Pol Antenna ' deblank( [mydat.time_coverage_start{:}] ) ' to ' deblank( [mydat.time_coverage_end{:}] ) ];
stime = regexprep( deblank( [mydat.time_coverage_start{:}] ), '[^0-9]', '');

% create a plot time tag and add as a textbox
nowtag = sprintf('%02d:', clock); nowtag = nowtag(1:16);

anti_center = 0;
nbeams = length(az);

el = mod((el + 180),360) - 180;  % limit elevations to lie between -180 and +180
                                 % caution -- not sure if this works with negative elevations

switch stype

case 1    % PPI
   n_az = histc(az, edges);      % create a histogram of azimuth bins
   tst = median(n_az([1 2 3 4 357 358 359 360]));   % determine if scan passes through north
   if( tst >= 1 );
   anti_center = mean((find(n_az(1:360) == 0)));   % this should return the anti-center
                                                    % fails if there are screwy transition beams
      n_az = n_az - 1;
      n_az(find(n_az < 0)) = 0;
      anti_center2 = mean((find(n_az(1:360) == 0)));
      if( abs( anti_center2 - anti_center) >= 5 );
          anti_center = anti_center2;
      end; 
%      az = mod((az+anti_center),360) - anti_center; % required because a PPI can be > 180 degrees
      az(find(az>anti_center)) = az(find(az>anti_center)) - 360;
     
   end;
   g1 = figure(1); plot(az, el);
   xlabel('Azimuth');ylabel('Elevation');
   title( mytitle, 'FontWeight','bold' );
   tHandle = text( 'String', nowtag, 'Units', 'normalized', 'Position', [0.02,.97],'Color', [.7 .7 .7] );

   hold on;
   x_lims = xlim;
   for nn=1:length(fa);
       y_pts = [ fa(nn) fa(nn)];
       plot(x_lims,y_pts, ':r');
   end;

% plot markers for transition flags
   tx_el = el(find(txf>0));
   tx_az = az(find(txf>0));
   plot(tx_az,tx_el,'or','MarkerSize',4);

   hold off;

   g2 = figure(2); plot((1:nbeams),az);
   xlabel('Beam Number');ylabel('Azimuth');
   title( mytitle, 'FontWeight','bold');
   tHandle = text( 'String', nowtag, 'Units', 'normalized', 'Position', [0.02,.97],'Color', [.7 .7 .7] );

   g3 = figure(3); plot((1:nbeams),el);
   xlabel('Beam Number');ylabel('Elevation');
   title( mytitle, 'FontWeight','bold');
   tHandle = text( 'String', nowtag, 'Units', 'normalized', 'Position', [0.02,.97],'Color', [.7 .7 .7] );

   daz = zeros((nbeams-1):1);
   del = zeros((nbeams-1):1);
   for i=1:(nbeams-1) 
      daz(i) = az(i+1) - az(i);
      del(i) = el(i+1) - el(i);
   end;

   g4 = figure(4); plot((1:nbeams-1), daz);
   xlabel('Beam Number');ylabel('Delta Azimuth');
   title( mytitle, 'FontWeight','bold');
   tHandle = text( 'String', nowtag, 'Units', 'normalized', 'Position', [0.02,.97],'Color', [.7 .7 .7] );

   g5 = figure(5); plot((1:nbeams-1), del);
   xlabel('Beam Number');ylabel('Delta Elevation');
   title( mytitle, 'FontWeight','bold');
   tHandle = text( 'String', nowtag, 'Units', 'normalized', 'Position', [0.02,.97],'Color', [.7 .7 .7] );

case 3    % RHI
   n_az = histc(az, edges);
   tst = median(n_az([1 2 3 4 357 358 359 360]));

   anti_center = mean((find(n_az(1:360) == 0)));   % this should return the anti-center
                                                    % fails if there are screwy transition beams
      n_az = n_az - 1;
      n_az(find(n_az < 0)) = 0;
      anti_center2 = mean((find(n_az(1:360) == 0)));
      if( abs( anti_center2 - anti_center) >= 5 );
          anti_center = anti_center2;
      end; 
      az(find(az>anti_center)) = az(find(az>anti_center)) - 360;
      fa(find(fa>anti_center)) = fa(find(fa>anti_center)) - 360;     


   g1 = figure(1); plot(az, el);
   xlabel('Azimuth');ylabel('Elevation');
   title( mytitle, 'FontWeight','bold');
   tHandle = text( 'String', nowtag, 'Units', 'normalized', 'Position', [0.02,.97],'Color', [.7 .7 .7] );

   hold on;
   y_lims = ylim;
   for nn=1:length(fa);
       x_pts = [ fa(nn) fa(nn)];
       plot(x_pts,y_lims, '-.r');
   end;

% plot markers for transition flags
   tx_el = el(find(txf>0));
   tx_az = az(find(txf>0));
   plot(tx_az,tx_el,'or','MarkerSize',4);

   hold off;

   g2 = figure(2); plot((1:nbeams),az);
   xlabel('Beam Number');ylabel('Azimuth');
   title( mytitle, 'FontWeight','bold');
   tHandle = text( 'String', nowtag, 'Units', 'normalized', 'Position', [0.02,.97],'Color', [.7 .7 .7] );

   g3 = figure(3); plot((1:nbeams),el);
   xlabel('Beam Number');ylabel('Elevation');
   title( mytitle, 'FontWeight','bold');
   tHandle = text( 'String', nowtag, 'Units', 'normalized', 'Position', [0.02,.97],'Color', [.7 .7 .7] );

   daz = zeros((nbeams-1):1);
   del = zeros((nbeams-1):1);
   for i=1:(nbeams-1);
      daz(i) = az(i+1) - az(i);
      del(i) = el(i+1) - el(i);
   end;

   g4 = figure(4); plot((1:nbeams-1), daz);
   xlabel('Beam Number');ylabel('Delta Azimuth');
   title( mytitle, 'FontWeight','bold');
   tHandle = text( 'String', nowtag, 'Units', 'normalized', 'Position', [0.02,.97],'Color', [.7 .7 .7] );

   g5 = figure(5); plot((1:nbeams-1), del);
   xlabel('Beam Number');ylabel('Delta Elevation');
   title( mytitle, 'FontWeight','bold');
   tHandle = text( 'String', nowtag, 'Units', 'normalized', 'Position', [0.02,.97],'Color', [.7 .7 .7] );

case {4,8}   % VER and SUR

   az2 = az;
   az2(find(az2>=359)) = NaN;  % handles transition through zero degrees, if 
                               % beams are spaced <= 1 degree.
   g1 = figure(1); plot(az2, el);
   xlabel('Azimuth');ylabel('Elevation');
   title( mytitle, 'FontWeight','bold');
   tHandle = text( 'String', nowtag, 'Units', 'normalized', 'Position', [0.02,.97],'Color', [.7 .7 .7] );

   hold on;
   x_lims = xlim;
   for nn=1:length(fa);
       y_pts = [ fa(nn) fa(nn)];
%       plot(x_lims,y_pts, '-.r');
       plot(x_lims,y_pts, ':r');
   end;

% plot markers for transition flags
   tx_el = el(find(txf>0));
   tx_az = az(find(txf>0));
   plot(tx_az,tx_el,'or','MarkerSize',4);

   hold off;

   g2 = figure(2); plot((1:nbeams),az2);
   xlabel('Beam Number');ylabel('Azimuth');
   title( mytitle, 'FontWeight','bold');
   tHandle = text( 'String', nowtag, 'Units', 'normalized', 'Position', [0.02,.97],'Color', [.7 .7 .7] );

   g3 = figure(3); plot((1:nbeams),el);
   xlabel('Beam Number');ylabel('Elevation');
   title( mytitle, 'FontWeight','bold');
   tHandle = text( 'String', nowtag, 'Units', 'normalized', 'Position', [0.02,.97],'Color', [.7 .7 .7] );

   daz = zeros((nbeams-1):1);
   del = zeros((nbeams-1):1);
   for i=1:(nbeams-1);
      daz(i) = az(i+1) - az(i);
      if( abs(daz(i)) > 180 );
         az_1 = mod((az(i)+180),360) - 180;
         az_2 = mod((az(i+1)+180),360) - 180;
         daz(i) = az_2 - az_1;
      end;
      del(i) = el(i+1) - el(i);
   end;

   g4 = figure(4); plot((1:nbeams-1), daz);
   xlabel('Beam Number');ylabel('Delta Azimuth');
   title( mytitle, 'FontWeight','bold');
   tHandle = text( 'String', nowtag, 'Units', 'normalized', 'Position', [0.02,.97],'Color', [.7 .7 .7] );

   g5 = figure(5); plot((1:nbeams-1), del);
   xlabel('Beam Number');ylabel('Delta Elevation');
   title( mytitle, 'FontWeight','bold');
   tHandle = text( 'String', nowtag, 'Units', 'normalized', 'Position', [0.02,.97],'Color', [.7 .7 .7] );

otherwise;
    disp(' ');
    disp([ 'We do not process this scan type ' stype  'Start = ' stime ]);
    disp(' ');
    dispo = 'bail';
end;

set(1,'Position',[ 219 701 560 420 ]);
set(2,'Position',[ 787 701 560 420 ]);
set(3,'Position',[1357 701 560 420 ]);
set(4,'Position',[ 787 196 560 420 ]);
set(5,'Position',[1357 196 560 420 ]);

if( strcmp(dispo, 'save') );
   pre = stime;
   pre = pre(1:14);
   pre = strcat( figd, '/scanp_', xscan{stype + 1}, '.', pre  );
   saveas(g1,strcat(pre, '.az_el.png'));
   saveas(g2,strcat(pre, '.bn_az.png')); 
   saveas(g3,strcat(pre, '.bn_el.png'));
   saveas(g4,strcat(pre, '.bn_daz.png'));
   saveas(g5,strcat(pre, '.bn_del.png'));
end;

plotstat = 0;
