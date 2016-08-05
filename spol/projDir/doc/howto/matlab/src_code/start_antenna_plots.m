function [stat] = start_antenna_plots( direc, dispo )

% Start-up routine for antenna plots

% direc = '/export/d2/rilling/DYN_test/cfradial/moments/sband';
% dispo = 'save';

if( ~exist('dispo'))   % if dispo = 'save', plots are saved in subdir "figs"
  dispo = 'no';
end;

f_name = select_files(direc, '/cfrad*.nc');

% the wilson/sellis test:
if( ~exist(deblank(f_name(1,:)),'file'))
   % need to bail-out
   stat = -1;
   fprintf('\n\nNo files selected.\n\nExit.\n\n');
   return;
end;

klim = size(f_name); klim = klim(1);
for kk=1:klim;
   mydat = read_pointing_info_h5( f_name(kk,:) );
   plotstat = plot_pointing_info( mydat, dispo );
   pause;
end;

stat = 1;
