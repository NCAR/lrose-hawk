function main_timeline_multi_plot( dir_id, myDate, forms, dispo )

% plots a timeline of the various collected cfradial data.
% The date is required; dispo tells the routine whether or 
% not you wish to save a plot

% dir_id is the shorthand indentifier(s) for the directories to 
% review.  Currently allowed values of dir_id are 'data.dmgt', 
% 'SPOL_a', 'SPOL_b', or 'pgen'
%
% myDate is the date in ccyymmdd format
%
% Allowed values for dispo:
%    blank        do not save
%    'save'       save as png
%    'savefig'    save as both png and matlab fig file
%    anythingelse do not save
%
% example:
%
%     main_timeline_multiplot({'data.dmgt' 'SPOL_a'}, '20111015','savefigs');
%
% Note that each spol computer system has a directory that is data.machine 
% For the data management system, this is data.dmgt; this name always starts
% with "data"
% The dir_ids get expanded into a complete directory name, using the 
% peculiar conventions of the spol network.
%
% There are a lot of issues that make this routine much more complicated than
% it should be.
%
%    RAR NCAR  Sep 2011

set(0,'DefaultTextInterpreter','none');
global rt_direc;

% NOTE: configure the egrep command for the radars/platform you desire
%  (search this file for egrep)

rt_direc = '';
Lspec = { '+k' '+r' '+b' '+g' '+m' '+k' '+r' '+b' '+g' '+m'};

if( ~exist('dispo'))   % if dispo = 'save', plots are saved in subdir "figs"
  dispo = 'no';
end;
% if we are running in batch, we mostly set the display to something other than :0
displaynum = getenv('DISPLAY');
if(~strcmp(displaynum,':0'))
   figd = '/home/operator/projDir/data/matlab/monitoring';
   batch = true;
else;
   figd = 'figs';
end;

if( exist(figd) ~= 7 ) && ( strcmp(dispo,'save') )
  mkdir(figd);
end;

% dtype = { 'moments' 'moments' 'covar'   'covar'   'partrain'};
% band  = { 'sband'   'kband'   'sband'   'kband'   'sband' };

legnd = {};
rdir = {};
dname = {};
sum_size = [];

egrep_data_format = [];

nlim = size(forms,2);
for jj=1:nlim;
egrep_data_format = [ egrep_data_format char(forms{jj}) ];
    if( jj == nlim ) continue; end;
    egrep_data_format = [ egrep_data_format '|' ];
end;

kout = 0;
nlim = size(dir_id,2);
for nn=1:nlim;
    if( strncmp(dir_id{nn},'data',4))
        tmpd = ['/data/operator/' dir_id{nn} ];
        tmpn = dir_id{nn};
    elseif( strncmp(dir_id{nn},'SPOL',4))
        tmpd = ['/usb/' dir_id{nn} '/field_data/dynamo'];
        command = ['ls -1 /usb/' dir_id{nn} '| fgrep SPOL'];
        [stat, tmpn ] = system(command);
        tmpn = deblank(tmpn);
    elseif( strncmp(dir_id{nn},'pgen',4))
        tmpd = ['/scr/' dir_id{nn} ];
        tmpn = dir_id{nn};
    else
        ['error on finding directories.  Exiting']
        exit;
    end;

    command = ['ls -d1 ' tmpd '/*/*/* | egrep "moments|covar|partrain" | egrep "sband|kband|smartr"' ' | egrep "' egrep_data_format '"' ];
    [status, result] = system(command);
    full_names = regexp(result,'\s','split');
    nlim = size(full_names,2) - 1;
    for kk=1:nlim;
        kout = kout + 1;
        tmp = char(full_names(kk));
        comp = regexp(tmp,'/','split');
        clim = size(comp,2);
        dformat{kout} = deblank(char( comp(clim-2)));
        dtype{kout} = deblank(char( comp(clim-1)));
        band{kout} = deblank(char( comp(clim)));
        rdir{kout}  = [tmpd '/' dformat{kout}];
        dname{kout} = tmpn;
    end;
end;

ntimelines = size(rdir,2);

figure; set(gca,'XLim',[0 86400],'YLim',[0.5 ntimelines+1]);
label_timeline_axes(ntimelines);
title([ myDate ' S-PolKa Data Existence (cfradial beamtime; dorade filetime)'] ,'FontWeight','bold', 'FontSize', 14);
yy = get(gca,'YLim');
yrange = yy(2) - yy(1);

% create a plot time tag and add as a textbox
nowtag = sprintf('%02d:', clock); nowtag = nowtag(1:16);
tHandle = text( 'String', nowtag, 'Units', 'normalized', 'Position', [0.02,1.02],'Color', [.7 .7 .7] );

hold on;

subs = size(dtype,2);
dlim = size(rdir,2);
for zz=1:dlim;
   ppos = ntimelines + 1 - zz;
%   nsub = zz - subs*floor((zz-1)/subs);
   if( ~strcmp(rt_direc, rdir{zz}))
     tHandle = text( 'String', [dname{zz} ' ' dformat{zz} ], 'Units', 'normalized', ...
              'Position', [0.2, (.4-yy(1)+ppos)/yrange],'Color', [.5 .5 .5] );
     nsub = 0;
   end;
   nsub = nsub + 1;
   rt_direc = rdir{zz};   % rt_direc is a required global variable, used in get_sorted_file_list
   
   legnd{zz} = [ dtype{zz} ' ' band{zz} ];
   tHandle = text( 'String', legnd{zz}, 'Units', 'normalized', 'Position', [0.04, (.4-yy(1)+ppos)/yrange],'Color', [.2 .2 .2] );

   f_names = get_sorted_file_list(myDate, dtype{zz}, band{zz});
   if(size(f_names,1) < 1 ) 
      plot( [1], ppos, Lspec{nsub});
      continue; 
   end;
   if( isempty(regexp(f_names{1},'2011') )); 
      plot( [1], ppos, Lspec{nsub});
      continue;
   end;

   allsecs = [];
   sum_size(zz) = 0;

   tmps = deblank(char(dformat{zz}));
   if (strncmp(tmps,'cfradial',8));
%      fprintf('\nfound a cfradial data set.  zz = %d\n',zz );
      for nn=1:size(f_names,1);
         secs = get_scan_daysecs( f_names{nn});
         f_inf = dir(f_names{nn});
         sum_size(zz) = sum_size(zz) + f_inf.bytes;
         allsecs = [ allsecs; secs ];
      end;
   elseif (strncmp(tmps,'dorade',6));
%      fprintf('\nfound a dorade data set.  zz = %d\n',zz);
      for nn=1:size(f_names,1);
         day_sec = get_time_from_fname( f_names{nn});
         f_inf = dir(f_names{nn});
         sum_size(zz) = sum_size(zz) + f_inf.bytes;
         allsecs = [ allsecs; day_sec ];
      end;
   else;
      fprintf('\nWe do not process %s\n\n', dformat{zz});
   end;
   plot( allsecs, ppos*ones(size(allsecs,1),1), Lspec{nsub});
end;

for kk=1:size(sum_size,2)
   sums{kk} = [ num2str(round(sum_size(kk)/1000000)) ' MB'];
end;
legend( sums, 'Location', 'EastOutside', 'Interpreter', 'none' );

ysize = max([ 540 (100 + (540/30)*kk ) ]); 

set(gcf,'Position',[1 100 1200 ysize ]);
set(gca,'Position',[.05 .050 0.82 0.890]);
%set(gca,'Position',[.05 .110 0.82 0.831]);

if( strncmp(dispo, 'save',4) );
%   myid = num2str(floor(1000*rand(1)));
   pre = strcat( figd, '/tmln_', myDate, '.');
%   set(gcf,'PaperPositionMode','auto', 'PaperType','uslegal','PaperOrientation','landscape','PaperUnits','normalized');
   set(gcf,'PaperPositionMode','auto', 'PaperUnits','inches','PaperSize',[14 8.5]);
   saveas(1,strcat(pre, 'png'));
end;

if(strcmp(dispo,'savefig'));
   saveas(gcf,strcat(pre, 'fig'));
end;

% pseudo test for batch operation, no prompt, no command window
% include these lines in all scripts designed to be run from the UNIX prompt

interactive_tst =  get(0,'ScreenDepth');

% if we are running in batch, we mostly set the display to something other than :0
displaynum = getenv('DISPLAY');
if(~strncmp(displaynum,':0',2))
   exit;
end;
