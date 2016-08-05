#!/usr/bin/perl

# Script to get data from CWB aws stations via ftp

# External modules

use Getopt::Long;
use Net::FTP;

# Usage statement

$usage=
  "Purpose: To get data from the CWB surface stations via ftp.\n" .
  "Usage: $prog [options as below ...]\n" .
  "  [-h] print usage\n" .
  "  [-debug] set debug mode on\n";

# initialize variables

$help=0;
$debug=0;
$force=0;
$UserName = "radman";
$PassWord = "radman!";
$SourceDir = "/home/radman/data/surface";
$HostName = "192.168.4.29";
$data_dir =  $ENV{'DATA_DIR'};
$DataDir = "$data_dir/raw/cwb/aws/orig";

#------------------------- Parse command line ----------------------------

&GetOptions("h!" => \$help,
	    "debug!" => \$debug);

if ($help) {
    print $usage;
    exit 0;
}

if ($debug) {
  print STDERR "---------------------------------------------\n";
  print STDERR "cwb_aws_ftp.pl\n";
  print STDERR "  UserName: $UserName\n";
  print STDERR "  PassWord: $PassWord\n";
  print STDERR "  SourceDir: $SourceDir\n";
  print STDERR "  HostName: $HostName\n";
  print STDERR "  DataDir is: $DataDir\n";
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

my $ftp = Net::FTP->new($HostName);
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
	    
	    $cmd =
		"LdataWriter -dir $DataDir -dtype raw -ext $raw_file_ext" .
		" -info1 tia_radar_ftp.pl -info2 $raw_file";
	    if ($debug) {
		print STDERR "Running: $cmd\n";
	    }
	    system($cmd);
	    
	} # if (!-f $raw_file)
	
    } # if ($LastGetTime le $raw_date)
    
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
