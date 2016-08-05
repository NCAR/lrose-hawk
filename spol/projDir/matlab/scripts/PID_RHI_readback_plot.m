function PID_RHI_readback_plot( myInfile );
%myInfile =  'output/PID_RHI_summary.20111018.out';

% read in data from the PID fractional volume files.
% Read all lines, average, and plot as histogram.
% Modified for batch mode.  Will attempt to eliminate bad volume results.
% Assumes if the myInfile argument is passed, then we are running in 
% non-interactive (batch) mode
%
% example:
%        PID_readback_plot('batch_PID/PID_summary.20110926.out')
%        PID_readback_plot('')


ptype = {'Cl' 'Drz' 'Lr' 'Mr' 'Hr' 'Ha' 'Rh' 'Gsh' 'GRR' 'Ds' 'Ws' 'Ic' 'Iic' 'Sld' 'Bgs' '2nd' 'Gcl' 'NoEc'};
req_angs    = 6;
req_volsize = 250000;

hours = [ 1 4 7 10 13 16 19 21 ];

batch = false;

if(exist('myInfile'));
   batch = true;
   infile = myInfile;
end;

if(~batch);
   reply = input('\nWhat is the name of your input file: ', 's');
   if isempty(reply)
      fprintf('\n  An input name is required.  Exit.\n\n')
      return;
   end;
   infile = reply;
end;

if( exist(infile) == 2)
   fid = fopen(infile, 'r');
else
  fprintf('ERROR - file not found: %s\n', myInFile);
  fprintf('Exiting.......\n');
  return;
end;

mytime = [];
time_dat = [];
part_dat = [];

while ~feof(fid);
    line = fgetl(fid);
% chop out any matlab comment lines
    A = regexpi(line,'%','once');
    if(~isempty(A));
       line = line(1:(A(1)-1));
    end;
    if isempty(line);
%      just go to the next loop
    elseif regexpi(line,'comment','once');
%       fprintf('%s\n',line);
    else
        thistime = line(1:22);
        line = line(22:numel(line));
        A = regexpi(line,'vol:','once');
        vtmp = line(A+4:numel(line));
        volsize = str2num(vtmp);
        line = line(1:(A-1));
        A = regexpi(line,'angs:','once');
        atmp = line(A+5:numel(line));
        angs = sscanf(atmp,'%f');
        if(numel(angs) < req_angs || volsize < req_volsize );
           continue;
        end;
        uangs = unique(angs);
        if( numel(uangs) ~= numel(angs));
            continue;
        end;
        line = line(1:(A(1)-1));
        tmp = sscanf(line,'%f');
        A = find(isnan(tmp));
        if(~isempty(A));
           continue;
        end;

        dstr = char(thistime);
        dstr = [ regexprep(dstr,'[\-:A-Z]',' ') ];
        tm = sscanf(dstr,'%d');
        mytime = [ mytime; thistime];
        time_dat = [ time_dat; tm' ];
        part_dat = [ part_dat; tmp'];   % each column contains the same type of particle
    end;
end;
fclose (fid);

class_frac = [];
class_frac = sum(part_dat);
class_frac = class_frac / size(part_dat,1);

class_lim = [17 18];

figure;
set(gcf,'Position',[1 1000 800 900]);
nn = 0;
for kk=class_lim;
    nn = nn + 1;
    subplot( 2,1,nn);
    hold on;        % use a hold on a subplot
    lgnd = {};
    for ii=1:kk;    % need to create single-point, multiple plots to get legend to work.
        plot([ii],[0],'.w');
        tmp = sprintf('%4s  %5.2f %%',ptype{ii},class_frac(ii));
        lgnd{ii} = tmp;
    end;

    legend( lgnd{1:kk}, 'Location', 'EastOutside', 'Interpreter', 'none', 'FontName','FixedWidth' );
    title([ mytime(1,:) ' to ' mytime(size(mytime,1),:) ' SPolKa RHI Vols' ] ,'FontWeight','bold', 'FontSize', 14);

    bar(class_frac(1:kk));
    set(gca,'XTick',[1:kk]);
    set(gca,'XTickLabel',ptype(1:kk));
  % set(gca,'Position',[.05 .110 0.82 0.831]);

    if(kk==17);
        ymax = max(class_frac(1:17));
        if(ymax < 5);
           ymax = 5;
        else
          ymax = ceil( (ymax)/5) * 5;
        end;
        set(gca,'YLim', [0 ymax]);
    end;

    if(kk==18);
        set(gca,'YLim',[0 100]);
    end;

    xlabel('NCAR Particle Type'); ylabel('Radar Volume-weighted Percent');

  % create a plot time tag and add as a textbox
    nowtag = sprintf('%02d:', clock); nowtag = nowtag(1:16);
    tHandle = text( 'String', nowtag, 'Units', 'normalized', 'Position', [0.02,.95],'Color', [.7 .7 .7] );

    hold off;

end;

if(batch);
   set(gcf,'PaperPositionMode','auto', 'PaperType','A4','PaperOrientation','portrait','PaperUnits','normalized');
   pngfile = regexprep(infile,'out$','png');
   saveas(gcf,pngfile);
end;

diurnal = zeros(numel(hours),18);
lgnd = {};

for kk=1:numel(hours);
   A = find(time_dat(:,4) == hours(kk));
   if( numel(A) > 0 );
      if(numel(A) == 1);
          diurnal(kk,:) = part_dat(A,:);
      else;
          diurnal(kk,:) = (sum(part_dat(A,:)))/numel(A);
      end;
   end;
   tmp = sprintf('%02d to %02d Z',hours(kk),(hours(kk)+1));
   lgnd{kk} = tmp;
end;

figure;
set(gcf,'Position',[200 1000 1200 900]);

for nn=1:2;
    subplot( 2,1,nn);
    bar(diurnal');   %'
    legend(lgnd,'Location', 'EastOutside', 'Interpreter', 'none', 'FontName','FixedWidth');
    set(gca,'XTick',[1:18]);
    set(gca,'XTickLabel',ptype(1:18));
% limit the scale for the top plot (clip the NoEcho category)
    if( nn == 1);
        ymax = max(max(diurnal(:,1:17)));
        if(ymax < 5);
           ymax = 5;
        else
          ymax = ceil( (ymax)/5) * 5;
        end;
        set(gca,'YLim', [0 ymax]);
        tHandle = text('String', {'Note:'; ' NoEc class'; ' is clipped'},'Units', 'normalized', 'Position',[.92 .93]);
        tHandle = text( 'String', nowtag, 'Units', 'normalized', 'Position', [0.02,.95],'Color', [.7 .7 .7] );
    end;
    xlabel('NCAR Particle Type'); ylabel('Radar Volume-weighted Percent');
    title([ 'Spol-Ka RHI Volumes Time-change of Echo Type ' mytime(1,:) ' to ' mytime(size(mytime,1),:) ] ,'FontWeight','bold', 'FontSize', 14);
end;

if(batch);
%   set(gcf,'PaperPositionMode','auto', 'PaperType','A4','PaperOrientation','landscape','PaperUnits','normalized');
   set(gcf,'PaperPositionMode','auto', 'PaperUnits','inches','PaperSize',[14 8.5]);
   pngfile = regexprep(infile,'out$','png');
   pngfile = regexprep(pngfile,'summary','diurnal');
   saveas(gcf,pngfile);
end;

% create individual line plots of time-evolving particle type

% figure;
% set(gcf,'Position',[300 1000 1200 900]);

% set(gca,'LineStyleOrder','-|--');
% hold on;

% plot( datenum(time_dat(:,:)),part_dat(:,1:14));

% rescale to semi-uniform Y-axis
%     ymax = max(max(part_dat(:,1:14)));
%     if(ymax < 5);
%        ymax = 5;
%     else
%        ymax = ceil( (ymax)/5) * 5;
%     end;
%     set(gca,'YLim', [0 ymax]);

% datetick('x',15);  % format number 15 is HH:MM
% legend( ptype{1:14}, 'Location', 'EastOutside', 'Interpreter', 'none', ...
%         'FontName','FixedWidth' );
% xlabel('NCAR Particle Type'); ylabel('Radar Volume-weighted Percent');
% title([ 'Spol-Ka RHI Volumes Time-change of Echo Type ' mytime(1,:) ' to ' mytime(size(mytime,1),:) ] ,'FontWeight','bold', 'FontSize', 14);
% tHandle = text( 'String', nowtag, 'Units', 'normalized', 'Position', [0.02,.95],'Color', [.7 .7 .7] );
% hold off;

% if(batch);
%   set(gcf,'PaperPositionMode','auto', 'PaperUnits','inches','PaperSize',[11 8.5]);
%   pngfile = regexprep(pngfile,'diurnal','timechg');
%   saveas(gcf,pngfile);
% end;

% pseudo test for batch operation, no prompt, no command window
% include these lines in all scripts designed to be run from the UNIX prompt

interactive_tst =  get(0,'ScreenDepth');

%if(numel(interactive_tst) == 1 && interactive_tst(1) == 0 );
%   fprintf('Found that ScreenDepth is a good test for nodisplay command line option.\n');
%   exit;
%end;

% if we are running in batch, we mostly set the display to something other than :0
displaynum = getenv('DISPLAY');
if(~strncmp(displaynum,':0',2))
   exit;
end;
