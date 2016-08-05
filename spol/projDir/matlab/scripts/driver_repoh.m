%Date:  October 11, 2011
%Author:  S. Powell, UW
%Description:  Driver program for batch_view_repoh.

clear all; close all; clc;

%***********USER DEFINED PARAMETERS*****************

%Comment out one of the 'dates' lines!

  dates = {'1'};  %Enter 1 for yesterday; otherwise yyyymmdd inside ' '.

  %To view files across more than one day (perhaps across 00Z) enter ['date1','date2'] in yyyymmdd.
  %dates = [{'20111004'},{'20111005'},{'20111007'},{'20111008'},{'20111009'},{'20111010'},{'20111011'},{'20111012'}];

snding_select = 'y';  %Enter 'y' to plot soundings, 'n' for no.
avg_snding = 'y';     %Compute mean DOE sounding over the period for which you wish to view data?
oneplot = 'y';        %Plot everything on one plot? ('y' or 'n').
azi_sep = 'y';        %Separate by sectors (SW,NW,SE,NE); recall beam blockage to west requires only scans >= 2.5deg to be included.
azibin = [0:90:360];  %Create analysis sectors by azimuth angle.  %Sectors must start at 0deg!
hgt_lev = 0.25;	      %What are sizes of height bins?
show_scat = 'n';      %Show a scatter plot?

repoh_mean = 'y';     %One big REPoH mean over the time period selected.  Will do for each azimuth if azi_sep is 'y'.
gm3 = 'y';	      %View in g m^-3 (y) or g kg^-1 (n)?

sounding_dir = '/home/operator/spowell/humidity_retrieval/sounding/matfiles/';  %Where are the sounding matfiles?
repoh_dir = '/home/operator/spowell/humidity_retrieval/REPoH/';         %Where are the REPoH matfiles?  Dates should be subdirectories within.

%*******DON'T CHANGE ANYTHING BELOW!!!**************

product_gen = 'n';  %Generate a product?  This should always be set to no unless in automated product-generating script not named driver_repoh.m
if product_gen == 'y'
  %Select filenames every three hours.
  %For loop across file sets.
    batch_view_repoh;  %Run somewhere in here.
    %print images
else
  filenames = [];  %Set empty array.
  hgtbin = [0:hgt_lev:5];  %Height bins for REPoH.
  modeset = 100;
  batch_view_repoh;
end


