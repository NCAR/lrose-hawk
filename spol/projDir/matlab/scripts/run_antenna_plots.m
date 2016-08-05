% Start-up routine for antenna plots

% direc = '/export/d2/rilling/DYN_test/cfradial/moments/sband';
direc = './cfradial/moments/sband';
%dispo = 'no';
 dispo = 'save';

f_name = select_files(direc, '/cfrad*.nc');

klim = size(f_name,1);
for kk=1:klim;
   mydat = read_pointing_info_h5( f_name(kk,:) );
   plotstat = plot_pointing_info( mydat, dispo );
   pause;
end;
