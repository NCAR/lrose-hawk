#!/usr/bin/perl

# Script to get surface min data from CWB aws stations via ftp

# External modules

use Getopt::Long;
use Net::FTP;

# Get script name

($script = $0) =~ s%.*/%%;

# Usage statement

$usage=
  "Purpose: To get data from the CWB surface stations via ftp.\n" .
  "Usage: $script [options as below ...]\n" .
  "  [-h] print usage\n" .
  "  [-debug] set debug mode on\n";

#------------------------- Parse command line ----------------------------

$help=0;
$debug=0;

&GetOptions("h!" => \$help,
            "debug!" => \$debug);
if ($help) {
  print $usage;
  exit 0;
 }

if ($debug) {
  print STDERR "---------------------------------------------\n";
  print STDERR "$script\n";
 }

# get current time

$nowstr = `date -u '+%Y,%m,%d,%H,%M,%S'`;
chop($nowstr);
if ($debug) {
  print STDERR "time now: $nowstr\n";
 }
($now_year, $now_month, $now_day, $now_hour, $now_min, $now_sec) = split(/,/, $nowstr);

# go back by five minutes, because the data has about a 5 min latency and
# we want to grab data correctly at 00:00

$five_mins_ago = `TimeCalc -sum $nowstr -300`;
chop($five_mins_ago);
if ($debug) {
  print STDERR "time 5 mins ago: $five_mins_ago\n";
 }
($prev_year, $prev_month, $prev_day, $prev_hour, $prev_min, $prev_sec) = split(/,/, $five_mins_ago);

# set ftp details

$UserName = "radman";
$PassWord = "radman!";
$SourceDir = "/home/radman/data/surface_min/${prev_year}_${prev_month}${prev_day}";
$HostName = "192.168.4.29";
$data_dir =  $ENV{'DATA_DIR'};
$yyyymmdd = "${prev_year}${prev_month}${prev_day}";
$ParentDir = "$data_dir/raw/cwb/surface_min";
$DataDir = "$ParentDir/$yyyymmdd";

if ($debug) {
  print STDERR "  FTP HostName: $HostName\n";
  print STDERR "  FTP UserName: $UserName\n";
  print STDERR "  FTP PassWord: $PassWord\n";
  print STDERR "  FTP SourceDir: $SourceDir\n";
  print STDERR "  Local Parent Dir is: $ParentDir\n";
  print STDERR "  Local Data Dir is: $DataDir\n";
 }

#---------- Check or make dir for SAT data, go there ---------------------

  if (! (-d $DataDir)) {
    if ($debug) {
      print STDERR "Making dir: $DataDir\n";
    }

    if (_mkdir($DataDir)) {
      printf STDERR "ERROR - $script\n";
      printf STDERR "  Cannot make dir: $DataDir\n";
      exit 1;
    }
  }
chdir($DataDir);

#--------------------- Set date and time ----------------------------------

($ymd, $hr) = &UtcTimeTag(0);  # this hour date and time 

#---------------------- get the time of the files grabbed last time -------

my $GetFile = "_last_get";
open (READ, $DataDir."/".$GetFile);
@LineValue=<READ>;
close(READ);
my $LastGet = $LineValue[0];
chomp $LastGet;   #get last file in local.
my $LastGetTime = substr($LastGet,0,15);
if ($LastGetTime eq "") {
  $LastGetTime = getMinGetTime();
  if ($debug) {
    print STDERR "First time to touch the _last_get file\n";
    print STDERR "  set it to $LastGetTime\n";
  }
 }

#-------------------- ensure we do not go back by more than 15 mins -------

  $MinGetTime = getMinGetTime();

if ($debug) {
  print STDERR "LastGetTime: $LastGetTime\n";
  print STDERR "MinGetTime: $MinGetTime\n";
 }

if ($LastGetTime < $MinGetTime) {
  $LastGetTime = $MinGetTime;
  if ($debug) {
    print STDERR "LastGetTime too old\n";
    print STDERR "  Setting to: $LastGetTime\n";
  }
 }

#------------- open FTP connection, get list of available files ----------

if ($debug) {
  $ftp = Net::FTP->new($HostName, Passive=>false, Timeout=>60, Debug=>1);
 } else {
  $ftp = Net::FTP->new($HostName, Passive=>false, Timeout=>60);
 }

if (!$ftp) {
  if ($debug) {
    print STDERR "ftp: Cannot connect to primary host: $HostName\n";
  }
  exit(0);
 }

$ftp->login($UserName, $PassWord);
$ftp->binary();
$ftp->pasv();
$ftp->cwd($SourceDir);
my @filelist = $ftp->dir();

#-------------- get all the newer files  ------------------

foreach (@filelist) {

  my @raw_files = split(" ", $_);
  $raw_file = $raw_files[8];
  $raw_date = substr($raw_file,0,15);

# check that this is a mesonet 1-min file

  if ($raw_file =~ /mes_m/) {

    if ($LastGetTime le $raw_date) {
      
      if (!-f $raw_file) {
            
            # record the timetag of this file
            
	open(GET,"> $GetFile");
	print GET $raw_file;
	close(GET);
            
            # get the file
	if ($debug) {
	  print STDERR "--> Getting file: $raw_file\n";
	}
	$ftp->get($raw_file);       
            
            # get file extention 
	my $raw_file_ext = substr($raw_file,16);
            
            # write latest data info

	$year = substr($raw_file, 0, 4);
	$month = substr($raw_file, 5, 2);
	$day = substr($raw_file, 8, 2);
	$hour = substr($raw_file, 11, 2);
	$min = substr($raw_file, 13, 2);
	$sec = "00";
	$ltime = "$year$month$day$hour$min$sec";
            
            $cmd =
                "LdataWriter -dir $ParentDir -ltime $ltime -dtype raw -ext txt" .
	      " -writer $script -rpath ${yyyymmdd}/$raw_file";
            if ($debug) {
	      print STDERR "Running: $cmd\n";
            }
            system($cmd);
            
      } # if (!-f $raw_file)

    } # if ($LastGetTime le $raw_date)

  } # if ($raw_file =~ /mes_m/) 
    
} # foreach

$ftp->quit;

# quit

exit(0);

#====================== sub UtcTimeTag =====================================

  sub UtcTimeTag{

  my (%MonCvrt, @date, $year, $mon, $day, $hour, $ymd, $hr);
  %MonCvrt = ( '01' => 'Jan', '02' => 'Feb', '03' => 'Mar', '04' => 'Apr',
	       '05' => 'May', '06' => 'Jun', '07' => 'Jul', '08' => 'Aug',
	       '09' => 'Sep', '10' => 'Oct', '11' => 'Nov', '12' => 'Dec');
  @date = gmtime(time + $_[0]); #
  $year = $date[5] + 1900;
   #remove the first two digital number from the 4 digitals 
  $year = substr($year,2,2);
  $mon  = $date[4] + 1;
  if ($mon < 10 ) { $mon = "0"."$mon"; }
  $day  = $date[3];
  if ($day < 10 ) { $day = "0"."$day"; }
  $hour = $date[2];
  if ($hour < 10 ) { $hour = "0"."$hour"; }
  #$min = $date[1];
  $ymd = $year.$mon.$day;   # Format of "20021220" 
  $hr = $hour;

  return $ymd, $hr;

}

#====================== compute min get date =========================
#
# Only get data back in time by 15 minutes
#

  sub getMinGetTime {

  $now = time();
  $minTime = $now - 900;

  ($msec, $mmin, $mhour, $mday, $mmonth, $myear, $mwday, $myday)
  = gmtime($minTime);

  $myear += 1900;
  $myear2d = $myear % 100;
  $mmonth += 1;

  $minTime = sprintf("%.2d%.2d%.2d%.2d%.2d%.2d",
		     $myear2d, $mmonth, $mday,
		     $mhour, $mmin, $msec);

  return $minTime;
    
}

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
