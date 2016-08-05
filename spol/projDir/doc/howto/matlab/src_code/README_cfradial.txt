The routines included here are designed to work with the latest
version of CfRadial format S-PolKa data.  The routines are provided as
examples, and my even be useful.  There are no guarantees provided
with any of the routines.

CfRadial and Matlab:
====================

CfRadial are written in netCDF4 with HDF5 compression.  This format
will be used as the native format for S-Pol data in DYNAMO.

Within Matlab, you must use the HDF5 routines to read the CfRadial
compressed files.  Matlab R2011a has in-built support for HDF5, with
the inclusion of some new, "high level" routines.  It is assumed that
you are using R2011a or better.

HDF5 is efficient, in that if you know the name of the parameter that
you want, you can quickly recover that paramter from an HDF5 through
use of addressing to the appropriate place in a file.  In contrast, if
you wish to read an entire file, HDF5 is not terrribly efficient, and
the Matlab built-in routines can take as long as 20 seconds to scan an
entire S-Pol volume file.

The most time-consuming part of reading S-Pol CfRadial files is in
first determining the full set of attributes within a file.  If you
can assume that the general nature of a file remains unchanged over
some time period, you can read the attributes once, and then just
recover the parameters you require for succeeding files.  This would
be a highly efficient approach.


Some CfRadial Features
======================

CfRadial has the option of *not* using HDF5 compression.  I such a
case, you can just use netcdf routines to manipulate the data.

CfRadial can have a mix of variables that requiring application of a
scale and bias.

CfRadial data may use "ragged beams": beams may be clipped to save
storage space.  Generally, clipping is constant with elevation tilt,
but there is no guarantee that this will always be the case.

CfRadial uses a few parameters whose names begin with an underscore
(_).  Matlab will upchuck on these if you incorporate the name in a
structure.

The routine "get_and_scale_hdf5_data.m" handles the scaling/no
scaling, and creates beams of uniform length.  The routine also
modifies a parameter name if it begins with an underscore.


Strategy
========

CfRadial/HDF5 files are read in two passes: one to read the
attributes, another pass to recover the desired parameters.
Attributes and parameters are stored in separate Matlab structures.

A separate routine is used to inspect the Attributes structure to
determine which parameters are "radar space" parameters.


Data file organization issues
==============================

Other routines are needed to account for organization of files on the
S-Pol RAID system.  The CfRadial files are written into subdirectories
based upon data type, radar wavelength, scan type, and then date.

Typical directories might be (from some TBD starting directory):

./cfradial/covar/kband/sur/20110419
./cfradial/covar/kband/rhi/20110419
./cfradial/covar/kband/sec/20110419
./cfradial/covar/sband/sur/20110419
./cfradial/covar/sband/rhi/20110419
./cfradial/covar/sband/sec/20110419

./cfradial/moments/kband/sur/20110419
.
.
./cfradial/moments/sband/sur/20110419
.
.

So, depending upon what kind of scans you want to review, and which
radar, not to mention the "data type", you need to be aware of the
directory structure.

If you wish to review *all* files for a given day (I do this when I
review accuracy of antenna pointing), you need a time-sorted list of
file names.

This is provided in the routine "get_sorted_file_list.m"


Some Reasonable Examples
========================

I have only a few routine that I consider operationally ready.  

timeline_multi_plot inspects all of the CfRadial files for a given
day, and plots a time history of every beam of data.  This is useful
in determining periods of missing data for any of our multiple data
sets.  You can determine if you have lost Ka data compared to S-band
data, or you can see that the S-band transition beams have been
deleted from the covar data set.  This routine can pass through ~30 GB
of files in less than a minute (this really shows the efficiency of
HDF5).

[Note: timeline_brief_multi_plot.m is a poor cousin of the
timeline_multi_plot routine, using the time encoded in the filenames
for the timeline plot; this was done so DORADE sweep files could be
monitored].

The AntPerf.m routine is a fully GUI-driven program to display antenna
pointing performance information.  [Note: I need to track down an
error with the default starting directory name].

Under Development
=================

The routines here are still evolving, but are likely to go into DYNAMO
in nearly the current condition.  If you find errors, or make
improvements, please let me know.

Bob Rilling
rilling@ucar.edu
