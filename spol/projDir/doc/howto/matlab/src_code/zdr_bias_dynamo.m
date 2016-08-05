%  MatLab routine to compute Zdr bias from vertically pointing data
%
%  Requires a correct pathname to the CfRadial files
%  Opens a single file from the vert directory, at the user's selection

%  Requires that each file has the parameters ZDR, DM, and LDR.  Prepares ZDR
%  by excluding the following data (nominal values; edit in the code, not here):
%
%           range < 3.0 km   and range > 15.0 km   adjust, as reasonable
%           horizontal co-polar power < -100 dBm   you can change this to be as low as -110
%           horizontal co-polar power > -47 dBm    you can change this to be as high as -43
%           LDR   > -20 dB                         LDR is high for non-spherical particles
%           RHOHV < .96                            not necessarily critical
%

set(0,'DefaultTextInterpreter','none');
mydir = '/scr/pgen/cfradial/moments/sband/vert';

l_range   =    3.0 * 1000.0;
u_range   =   15.0 * 1000.0;
ldr_thres =  -20.0;
l_power   = -100.0;
u_power   =  -47.0;
rho_thres =     .96;   % this can throw out 10% of gates


db_low_clip = -20.0;
db_hi_clip  =  20.0;
lin_low_clip = -1.0;
lin_hi_clip  = 100.0;

f_name = select_files(mydir, '/cfrad*VER.nc');

[ ATT ] = get_hdf5_param_atts( f_name(1,:) );
% Flds = {'DBMHC_F' 'ZDRM' 'LDRH_F' 'RHOHV_F' };  % ZDRM is the non-corrected zdr
Flds = {'DBMHC' 'ZDRM' 'LDRH' 'RHOHV' };  % ZDRM is the non-corrected zdr

kk=1;

f_lim = size(f_name,1);

v_ZDR = [];
v_LDR = [];
v_DBM = [];
v_RHO = [];
v_az  = [];
v_el  = [];
v_tx  = [];


% for this code, assume that the number of gates is constant between
% chosen volumes

for kk=1:f_lim;
   SWP = get_and_scale_hdf5_data(deblank(f_name(kk,:)), ATT, [Flds { ...
       'time_coverage_end' 'time_coverage_start' 'prt' 'n_samples' ...
       'time' 'range' 'elevation' 'azimuth' 'antenna_transition'}]);

       start_time{kk} = SWP.time_coverage_start;
       stop_time{kk} = SWP.time_coverage_end;

       l_gate = find((SWP.range >= l_range),1,'first');
       u_gate = find((SWP.range <= u_range),1,'last');

       v_az = [ v_az; SWP.azimuth];
       v_el = [ v_el; SWP.elevation];
       v_tx = [ v_tx; SWP.antenna_transition ];

       v_ZDR = [ v_ZDR; SWP.ZDRM(:,l_gate:u_gate)];
%       v_LDR = [ v_LDR; SWP.LDRH_F(:,l_gate:u_gate)];
%       v_RHO = [ v_RHO; SWP.RHOHV_F(:,l_gate:u_gate)];
%       v_DBM = [ v_DBM; SWP.DBMHC_F(:,l_gate:u_gate)];

       v_LDR = [ v_LDR; SWP.LDRH(:,l_gate:u_gate)];
       v_RHO = [ v_RHO; SWP.RHOHV(:,l_gate:u_gate)];
       v_DBM = [ v_DBM; SWP.DBMHC(:,l_gate:u_gate)];

end;

% implicitly filter out data by setting undesired data to NaN.

v_ZDR(find(v_DBM<l_power))   = NaN;
v_ZDR(find(v_DBM>u_power))   = NaN;
v_ZDR(find(v_LDR>ldr_thres)) = NaN;
v_ZDR(find(v_RHO<rho_thres)) = NaN;

v_ZDR(find(v_ZDR>db_hi_clip))  = NaN;
v_ZDR(find(v_ZDR<db_low_clip)) = NaN;

XX = reshape(v_ZDR,numel(v_ZDR),1);
Xmean = nanmean(XX);
Xstd = nanstd(XX);

YY = 10.^(XX/10.);
Ymean = nanmean(YY);  % find the mean of array values that are good numbers (instead of NaN)
Ystd = nanstd(YY);

ptag = [ deblank(char(start_time{1})') ' to ' deblank(char(stop_time{f_lim})') ];
dstr = deblank(char(start_time{1})');
dstr = [ regexprep(dstr,'[\-:A-Z]','') ];
tag = [ 'SPOL_' dstr ];

xbin = 0.2;
xd = db_low_clip:xbin:db_hi_clip;  % note: this range should be expanded, or the data need to be filtered.

X_bins = histc(XX,xd);
ngates = numel(XX) - numel( find(isnan(XX)) );

g1 = figure(1); hist(XX,xd); title([ 'S-Pol Zdr Vertical Pointing, ' ptag ]);
xlabel('Zdr, dB'); ylabel('Bin Count');

[tstr, errmsg] = sprintf('ngates = %5d\nmean = %5.3f dB\nstd dev = %4.2f dB\nbinsize = %4.2f dB', [ ngates  Xmean Xstd xbin ]);
x_lims = xlim;  x_pos = .7 * (x_lims(2) - x_lims(1)) + x_lims(1);
y_lims = ylim;  y_pos = .8 * (y_lims(2) - y_lims(1)) + y_lims(1);
text(x_pos, y_pos,tstr);

of = ([ tag '_all_data.png' ]);
saveas(g1,of);

ybin = 1.0;
yd = -1.0:ybin:lin_hi_clip;  % note: this range should be expanded, or the data need to be filtered.


Y_bins = histc(YY,yd);
YY(find(YY>lin_hi_clip)) = NaN;

ngates = numel(YY) - numel( find(isnan(YY)) );
g2 = figure(2); hist(YY,yd); title([ 'S-Pol Zdr Vertical Pointing, ' ptag ]);
xlabel('Zdr, linear'); ylabel('Bin Count');

[tstr, errmsg] = sprintf('ngates = %5d\nlin mean = %5.3f\nstd dev = %4.2f\nbinsize = %4.2f', [ ngates  Ymean Ystd ybin ]);
x_lims = xlim;  x_pos = .7 * (x_lims(2) - x_lims(1)) + x_lims(1);
y_lims = ylim;  y_pos = .8 * (y_lims(2) - y_lims(1)) + y_lims(1);
text(x_pos, y_pos,tstr);

of = ([ tag '_lin_data.png' ]);
saveas(g2,of);

XX = XX(find(abs(XX) < 4.0));
Xmean = mean(XX);
Xmode = mode(XX);
Xmedian = median(XX);
Xstd = std(XX);
ngates = length(XX);

xbin = .04;
xd = -4.0:xbin:4.0;

l_xdl = 10^(-4.0/10);
l_xdu = 10^( 4.0/10);
l_xd = floor(l_xdl):0.02:ceil(l_xdu);
YY = YY(find(YY <= l_xdu));
YY = YY(find(YY >= l_xdl));

g3 = figure(3); hist(XX,xd); title([ 'S-Pol Zdr Vertical Pointing, starting at ' ptag ]);
xlabel('Zdr, dB'); ylabel('Bin Count');

[tstr, errmsg] = sprintf('ngates = %5d\nmean = %5.3f dB\nmode = %5.3f dB\nmedian = %5.3f dB\nstd dev = %4.2f dB\nbinsize = %4.2f dB', ...
          [ ngates  Xmean Xmode Xmedian Xstd xbin ]);
x_lims = xlim;  x_pos = .7 * (x_lims(2) - x_lims(1)) + x_lims(1);
y_lims = ylim;  y_pos = .8 * (y_lims(2) - y_lims(1)) + y_lims(1);
text(x_pos, y_pos,tstr);

of = ([ tag '_filt_data.png' ]);
saveas(g3,of);

ngates = numel(YY);


g4 = figure(4); hist(YY,l_xd); title([ 'S-Pol Zdr Vertical Pointing, starting at ' ptag ]);
xlabel('Zdr, linear'); ylabel('Bin Count');

[tstr, errmsg] = sprintf('ngates = %5d\nlin mean = %5.3f\nstd dev = %4.2f\nbinsize = %4.2f', [ ngates  Ymean Ystd ybin ]);
x_lims = xlim;  x_pos = .7 * (x_lims(2) - x_lims(1)) + x_lims(1);
y_lims = ylim;  y_pos = .8 * (y_lims(2) - y_lims(1)) + y_lims(1);
text(x_pos, y_pos,tstr);

of = ([ tag '_filt_lin_data.png' ]);
saveas(g4,of);
