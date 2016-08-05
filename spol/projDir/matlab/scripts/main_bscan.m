% Start-up routine for vertical pointing plots

direc = '/data/operator/data.dmgt/cfradial';
set(0,'DefaultTextInterpreter','none');

f_name = select_files(direc, '/cfrad*.nc');

% make the assumption that Attributes will not change over the next
% few volumes (this is a serious assumption!)

[ ATT ] = get_hdf5_param_atts( f_name(1,:) );
Flds = determine_radar_fields( ATT );
sFlds = select_params(Flds);

klim = size(f_name,1);
for kk=1:klim;
   SWP = get_and_scale_hdf5_data(deblank(f_name(kk,:)), ATT, [sFlds { ...
       'time_coverage_end' 'time_coverage_start' 'prt' 'n_samples' ...
       'time' 'range'}]);
   ngates = size(SWP.(sFlds{1}), 1);
   nbeams = size(SWP.(sFlds{1}), 2);
   blankbeam(1:ngates) = NaN;
   blankbeam = blankbeam';

   time_width = double(SWP.n_samples) .* SWP.prt;

   delta_t = [];
   for jj=1:nbeams-1;
       delta_t(jj) = SWP.time(jj+1) - SWP.time(jj);
   end;
   delta_t(nbeams) = delta_t(nbeams-1);

   % need to account for gaps in beam time history when using
   % pcolor for plotting (pcolor smears adjacent beams)

   nb = 0;
   for jj=1:nbeams;
       nb = nb + 1;
       if( delta_t(jj) > time_width(jj))
           nb = nb + 1;
       end;
   end;
   btime = zeros(1,nb);
   mydat = zeros(ngates,nb);
   mydat(:,:) = NaN;
   
   nflds = size(sFlds,2);
   beam = {};
   for nf=1:nflds;
       beam.(sFlds{nf}) = mydat;
       nb = 0;
       for jj=1:nbeams;
           nb = nb + 1;
           beam.(sFlds{nf})(:,nb) =  SWP.(sFlds{nf})(:,jj);
           btime(nb) = SWP.time(jj);
           if( delta_t(jj) > time_width(jj))
               nb = nb + 1;
               btime(nb) =  (btime(jj) + time_width(jj));
           end;
       end;
   end;

   % do the plotting; pause between sets of plots to allow review
   % and saving.

   dt = median(delta_t);   % this is only an approximation to avg dt
   if(dt == 0 );  % this happens for systems with limited time resolution, including smartr
      dt = (SWP.time(nbeams) - SWP.time(1))/nbeams;
   end;
   X = [ SWP.time(1):dt:(SWP.time(nbeams)+2*dt)]; % add at least
                                                  % one extra dt
   Y = [1:ngates]';
   [x,y] = meshgrid(btime,[1:ngates]);
   param = [];
   p = [];
   for nf=1:nflds;

      param = zeros(ngates,size(X,2));
      param(:,:) = NaN;
      tlim = size(SWP.time,1);
      for jj=1:tlim;
          ind = round((SWP.time(jj) - SWP.time(1))/dt) + 1;
          param(:,ind) = SWP.(sFlds{nf})(:,jj);
      end;

      figure;
      p(nf) = pcolor(X,Y,param ); hold on;
      set(p(nf),'EdgeColor', 'none');
      title([ deblank( [SWP.time_coverage_start{:}] ) ' SpolKa ' ATT.(sFlds{nf}).long_name ], ...
            'FontWeight','bold', 'FontSize', 14);
      xlabel('Seconds');ylabel('Gate Number');
      hcb3 = colorbar('Location','EastOutside');
      hold off;
   end;
   pause;
end;

% this code is more "correct", but is too slow:

%   for nf=1:nflds;

       % The gridding is painfully slow.  This can be speeded-up
       % with a custom, "nearest beam" data plug-in.
       % The hooks are there with the X array -- will add in
       % future.  (this will follow the same pattern as the 
       % "stuffing" of the beam structure, above)

%      param = griddata(x, y, beam.(sFlds{nf}),X,Y,'nearest');
%      figure;
%     p(nf) = pcolor(X,Y,param ); hold on;
%      set(p(nf),'EdgeColor', 'none');
%      title([SWP.time_coverage_start ' SpolKa ' ATT.(sFlds{nf}).long_name ],'FontWeight','bold', ...
%      'FontSize', 14);
%      xlabel('Seconds');ylabel('Gate Number');
%      hcb3 = colorbar('Location','EastOutside');
%      hold off;
%   end;
