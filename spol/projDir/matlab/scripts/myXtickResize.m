function myXtickResize(src,eventdata,ntimelines);

% global ntimelines;

% relabels an X-axis time, where data are plotted in seconds.
% Changes tick marks to strings in the form HH:MM:SS.mm
% Also prevents re-scaling of the Y axis when zooming in or out.

% This routine is referenced through the function "label_timeline_axes", 
% and should always be paired with that routine

% The routine does not change the number or location of the X-axis 
% tick marks; the routine only re-labels the marks.
% (this behavior may be changed in the future)

xtics = get(gca,'XTick');

hh = floor(xtics/3600);
mm = floor(mod(xtics,3600)/60);
ss = floor(mod(xtics,60));  % this creates fractional seconds
ff = floor(mod(xtics,1)*100);

for nn=1:max(size(xtics))
  tictime{nn} = sprintf('%02d:%02d:%02d.%02d', hh(nn), mm(nn), ss(nn), ff(nn));
end;

set(gca, 'XTickLabel',tictime);
set(gca, 'YLim', [0.5 ntimelines+1 ]);
set(gca, 'YTickLabel',[ ]);
