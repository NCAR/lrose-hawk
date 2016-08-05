#!/usr/bin/perl
#
# FTP dc3 image files to the field catalog
#
# Mike Dixon, RAP, NCAR, Boulder, CO, USA
# Feb 2008
#

# system Perl modules

use Net::FTP;
use Time::Local;
use Getopt::Long;
 
#
# RAP Perl modules
#

use Env qw(RAP_LIB_DIR);
use lib "$RAP_LIB_DIR/perl5/";
use Procmap;
use Toolsa;

$debug = 1;                              # Ordinary debugging flag.
$verbose = 1;                            # Verbose debugging flag.
$proj_dir = $ENV{'PROJ_DIR'};

#------------------------- Parse command line ----------------------------

($prog = $0) =~ s%.*/%%;                 # Determine program basename.
&GetOptions("unix_time=s" => \$unix_time,
	    "year=s" => \$year,
	    "month=s" => \$month,
	    "day=s" => \$day,
	    "hour=s" => \$hour,
	    "min=s" => \$min,
	    "sec=s" => \$sec,
            "debug!" => \$debug,
            "verbose!" => \$verbose,
	    "rap_data_dir=s" => \$rap_data_dir,
	    "full_path=s" => \$full_path,
	    "abs_dir_path=s" => \$abs_dir_path,
	    "sub_dir=s" => \$sub_dir,
	    "rel_dir=s" => \$rel_dir,
	    "file_ext=s" => \$file_ext,
	    "data_type=s" => \$data_type,
	    "user_info1=s" => \$user_info1,
	    "user_info2=s" => \$user_info2,
	    "is_forecast=s" => \$is_forecast,
	    "forecast_lead_secs=s" => \$forecast_lead_secs,
	    "writer=s" => \$writer,
	    "data_late_secs=s" => \$data_late_secs,
	    "rel_data_path=s" => \$rel_data_path);

$orig_dir = $full_path;
$file_name = $rel_data_path;
$xml_name = $file_name;
$xml_name =~ s/png/xml/;

$data_path = $orig_dir . '/' . $file_name;
$xml_path = $orig_dir . '/' . $xml_name;
$day_str = sprintf "%.4d%.2d%.2d", $year, $month, $day;
$time_str = sprintf "%.4d%.2d%.2d%.2d%.2d%.2d", $year, $month, $day, $hour, $min, $sec;
$minute_str = sprintf "%.4d%.2d%.2d%.2d%.2d", $year, $month, $day, $hour, $min;

if ($debug) {
    print STDERR "Running handle_images_dc3:\n";
    print STDERR "  orig_dir: $full_path\n";
    print STDERR "  file_name: $file_name\n";
    print STDERR "  data_path: $data_path\n";
    print STDERR "  xml_path: $xml_path\n";
    print STDERR "  day_str: $day_str\n";
    print STDERR "  time_str: $time_str\n";
}

if ($file_name !~ /.png/) {
    if ($debug) {
        print STDERR "Not a PNG file, so ignoring\n";
        exit 0;
    }
}

#------------------------- initialize ----------------------------

$| = 1;                           # Unbuffer standard output.
umask 002;                        # Set file permissions.
$ftp_timeout = 60;                # Max time for single file transfer

# ----------- move the CIDD-created files to a day dir  -----------

$day_dir = $orig_dir . '/' . $day_str;
$data_path_moved = $day_dir . '/' . $file_name; 
$xml_path_moved = $day_dir . '/' . $xml_name; 

if ($debug) {
    print STDERR "Moving files to day dir: $day_dir\n";
 }
system("mkdir -p $day_dir");
system("/bin/mv $data_path $day_dir");
system("/bin/mv $xml_path $day_dir");

# ----------- convert black to transparent ---------------
# ----------- rename at the same time --------------------

$trans_dir = $orig_dir . '/trans/' . $day_str;

$field_name = "UNKNOWN";
if ($file_name =~ /DBZ/) {
    $field_name = "DBZ";
} elsif ($file_name =~ /VEL/) {
    $field_name = "VEL";
} elsif ($file_name =~ /WIDTH/) {
    $field_name = "WIDTH";
} elsif ($file_name =~ /ZDR/) {
    $field_name = "ZDR";
} elsif ($file_name =~ /PID/) {
    $field_name = "PID";
} else {
    print STDERR "Unknown file type: $file_name\n";
    exit (1);
}

$trans_name = 'research.CHILL.' . $minute_str . '.' . $field_name . '.png';
$trans_path = $trans_dir . '/' . $trans_name;

if ($debug) {
    print STDERR "Creating transparent file: $trans_path\n";
}

system("mkdir -p $trans_dir");
system("convert -transparent black -quality 90 $data_path_moved $trans_path");

#--------------- send files to DC3 for upload to GV -------------------------

$ftp_host = "catalog1.eol.ucar.edu"; 
$user = "anonymous";       # The remote username.
$passwd = "dixon\@ucar.edu";      # The remote password.
$targetdir = "pub/incoming/OSM/GV/"; # The remote target data directory.

&send_file($ftp_host, $user, $passwd, $targetdir, $trans_path, $trans_name);

#----------------- send files to EOL DC3 catalog ------------------------------

$ftp_host = "catalog1.eol.ucar.edu"; 
$user = "anonymous";       # The remote username.
$passwd = "dixon\@ucar.edu";      # The remote password.
$targetdir = "pub/incoming/catalog/dc3/"; # The remote target data directory.

&send_file($ftp_host, $user, $passwd, $targetdir, $trans_path, $trans_name);

exit 0;

# --------------------------------------------------------------------
# send_file function: Send file to remote host
# Arg: host

sub send_file {

  local($ftp_host, $user, $passwd, $targetdir, $filepath, $filename) = @_;
  local($ftp);
  
  if ($debug) {
    print STDERR "Sending: ftp_host: $ftp_host\n";
    print STDERR "         user: $user\n";
    print STDERR "         passwd: $passwd\n";
    print STDERR "         targetdir: $targetdir\n";
    print STDERR "         file path: $filepath\n";
    print STDERR "         file name: $filename\n";
  }
  
  $ftp = Net::FTP->new($ftp_host, Passive=>true, Timeout=>$ftp_timeout);
  if (!$ftp) {
    print STDERR "ftp-new failure\n";
    return;
  }
  if ($ftp->login($user, $passwd) == 0) {
    print STDERR "ftp-login failure, user: $user, password: $pass\n";
    $ftp->quit;
    return;
  }
  
  $ftp->mkdir($targetdir,"true");
  
  if ($ftp->cwd($targetdir) == 0) {
    print STDERR "ftp-cwd failure\n";
    $ftp->quit;
    return;
  }
  
  $ftp->binary;
  
  if ($ftp->put($filepath, $filename) != 0) {
    print STDERR "ftp-put failure\n";
    $ftp->quit;
    return;
  }
  
  $ftp->quit;
  
  if ($debug) {
    print STDERR "-->> success\n";
  }
  
}

