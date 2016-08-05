#! /usr/bin/perl
#
# wget_caa_data script
#
# Get sat data for TIMREX
#
# =================================================================

#------------------------------- Set defaults --------------------------
#
# External modules

use Getopt::Long;
use Env;

# Get program name

($script = $0) =~ s%.*/%%;

# Usage statement

$usage=
    "Purpose: To wgen sat data\n" .
    "Usage : $prog [options as below]\n" .
    "Options:\n" .
    "  [-h] print usage\n" .
    "  [-debug] set debug mode on\n";

# initialize command line variables

$help = 0;
$debug = 0;
$script = "wget_caa_data.pl";

# parse command line

&GetOptions("h!" => \$help,
	    "debug!" => \$debug);

if ($help) {
    print $usage;
    exit 0;
}

# get current unix time

$now_utime = time();
$now_time = `TimeCalc -cal $now_utime`;
($year, $month, $day, $hour, $min, $sec) = split(/,/, $now_time);
$run_time = sprintf("%.4d-%.2d-%.2d %.2d:%.2d:%.2d",
		    $year, $month, $day, $hour, $min, $sec);

if ($debug) {
  print STDERR "Running $script\n";
  print STDERR "Run-time: $run_time\n";
}

# compute directories

$home = $ENV{'HOME'};
$proj_dir = "$home/projDir";
$data_dir = "$home/projDir/data";

# loop through sub dirs

@sub_dirs = ("satVis/domain3",
	     "satIR/domain3",
	     "satVis/domain2",
	     "satIR/domain2",
	     "radar/mosaic3d");
foreach $sub_dir (@sub_dirs) {

# loop through likely times for data

for($relTime = -10800; $relTime < 3600; $relTime += 600){

  $file_time = `TimeCalc -sum $year,$month,$day,$hour,0,0 $relTime`;
  ($fyear, $fmonth, $fday, $fhour, $fmin, $fsec) = split(/,/, $file_time);

  if ($debug) {
    print STDERR "\n\n==========================================\n";
    print STDERR "Searching for next file\n";
    print STDERR "-->> relTime: $relTime\n";
    print STDERR "-->> file_time: $file_time\n";
  }

# compute file name and URL

  $filename = sprintf("%.4d%.2d%.2d/%.2d%.2d%.2d.mdv",
		      $fyear, $fmonth, $fday, $fhour, $fmin, $fsec);
  $url = "http://aoaws.caa.gov.tw/data/mdv/${sub_dir}/" . $filename;

  if ($debug) {
    print STDERR "Getting file from url: $url\n";
  }
  
# make local dir and go there

  $yymmdd = sprintf("%.4d%.2d%.2d", $fyear, $fmonth, $fday);
  $local_dir = "$data_dir/mdv/caa/$sub_dir/$yymmdd";

  if (_mkdir($local_dir)) {
    printf STDERR "ERROR - $script\n";
    printf STDERR "  Cannot make local dir: $local_dir\n";
    exit 1;
  }
  chdir("$local_dir");

# run wget, save the output in a log file

  $logfile = "/tmp/$script.out";
  $wget_cmd = "wget -N $url > $logfile 2>&1";
  if ($debug) {
    print STDERR "Running: $wget_cmd\n";
  }
  system($wget_cmd);

# scan log file to see if file was written
  
  @lines = `cat $logfile`;
  $fileDownloaded = 0;
  foreach (@lines) {
    if (m/Saving to/) {
      $fileDownloaded = 1;
    }
  }

  if ($fileDownloaded == 1) {
    
    if ($debug) {
      print STDERR "Downloaded file: $sub_dir/$filename\n";
      foreach (@lines) {
	print STDERR "====>> $_";
      }
    }
    
# write _latest_data_info

    $ltime = sprintf("%.4d%.2d%.2d%.2d%.2d%.2d",
		     $fyear, $fmonth, $fday, $fhour, $fmin, $fsec);
    $cmd =
      "LdataWriter -dir mdv/caa/$sub_dir -dtype mdv -ext mdv -ltime $ltime" .
      " -writer $script -rpath $filename";
    system($cmd);
    
  }

 } # relTime loop
 
} # foreach sub_dir loop

exit 0;

#---------------------------------------------------------------------------
# Subroutine: _mkdir
#
# Function:   Check whether $dir exists. Try to create it if it does not.
#
# Input: $dir - name of directory to check
# returns 0 on success, -1 on error

sub _mkdir {
  
  local($dir) = @_;
  
  if (!-d $dir) {

    if ($debug) {
      print(STDERR "INFO - _mkdir\n");
      print(STDERR "  dir $dir does not exist, attempting to create it.\n");
    }
    
    system("mkdir -p $dir");
    
    if (!-d $dir) {
      print(STDERR "ERROR - _mkdir\n");
      print(STDERR "  Cannot create dir: $dir.\n");
      return(-1);
    }
    
  }
  
  return (0);
  
}
