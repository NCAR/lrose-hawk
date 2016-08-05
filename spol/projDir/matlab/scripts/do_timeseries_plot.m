% make a plot using the time series
                              
function do_timeseries_plot(plotDates, ...
                            field, ...
                            fieldName, ...
                            fieldLabel, ...
                            titleText, ...
                            endDate, ...
                            maxHeight, ...
                            colorMapType, ...
                            minVal, ...
                            maxVal, ...
                            imageDir)


  fprintf('--->> making plot: %s\n', titleText);

  % create 2-D color plot with surfc

  figure(1)

  [ xgrid, ygrid ] = meshgrid(plotDates,0:0.1:(maxHeight-0.1));

  if ((minVal > -9990) & (maxVal < 9990))
      surfc(xgrid, ygrid, field, 'edgecolor', 'none'), ...
      shading interp, ....
      colormap(colorMapType), ...
      caxis([minVal maxVal])
  else
      surfc(xgrid, ygrid, field, 'edgecolor', 'none'), ...
      shading interp, ....
      colormap(colorMapType)
  end

  view(2);

  %  pcolor(plotDates,0:0.1:(maxHeight-0.1),field), shading interp

  % x ticks and labels are for dates (julian day)

  nTicks = 7;
  timeElapsed = plotDates(end) - plotDates(1);
  tickDelta = timeElapsed / nTicks;
  if (tickDelta < 2)
    tickDelta = tickDelta * 2;
  end
  tickDates = plotDates(1):tickDelta:plotDates(end);
  if (tickDates(end) ~= plotDates(end))
    tickDates = [ tickDates, plotDates(end) ];
  end  
  set(gca,'XTick',tickDates);
  % datetick('x','mmmdd-HHZ','keeplimits');
  datetick('x','mmmdd-HHZ','keepticks');

  startTime = datestr(plotDates(1),'yyyy/mm/dd');
  endTime = datestr(plotDates(end),'yyyy/mm/dd');
  timeLabel = strcat(['Time range: ', startTime, ' to ', endTime]);
  xlabel(timeLabel,'FontSize',14);

  % y axis is height

  ylabel('Height (km)','FontSize',14);
  ylabel(colorbar,fieldLabel);

  % title

  title(titleText,'FontSize',16);

  % save PNG file

  pname = strcat([imageDir, '/', fieldName, '_', endDate, '_000000', '.png']);
  fprintf('Saving image: %s\n', pname);
  print ('-dpng', pname);

return;


