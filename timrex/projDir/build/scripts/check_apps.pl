#!/usr/bin/perl
#
# check_apps: Check installed applications
#
# Usage:
#   daily_backup.pl <options>
#
#    Options:
#       -help                : Print usage
#       -debug               : debugging on
#       -list                : check list
#
#===================================================================================
# Get the needed PERL supplied library modules.
#===================================================================================

require 'getopts.pl';
use Getopt::Long;                                                                           
use Time::Local;#

#
# Get the program basename.
#

($prog = $0) =~ s|.*/||;

#
# Unbuffer standard output
#

$| = 1;

# set flushing

$OUTPUT_AUTOFLUSH = 1;

#
# Set file permissions
#

umask 002;

# Initialize command line arguments

$opt_debug = "";
$opt_params = "";

$usage =
    "\nUsage: $prog <options>\n" .
    "Options:\n" .
    "  -help                 :Print usage\n" .
    "  -dir                  :app dir (required)\n" .
    "  -list                 :app check list (required)\n" .
    "  -debug                :debugging on\n" .
    "\n";

# Get the arguments from the command line

$results = &GetOptions('help',
                       'dir:s',
                       'list:s',
                       'debug');

if ($opt_help) {
    print $usage;
    exit 0;
}

if (!$opt_list) {
    print "\nERROR - you must specify the app list\n";
    print $usage;
    exit 0;
}

if (!$opt_dir) {
    print "\nERROR - you must specify the app dir\n";
    print $usage;
    exit 0;
}

# read in the list of installed apps, from the app directory

opendir(DIRHANDLE, $opt_dir) || die "Cannot open dir: $opt_dir: $!";
$count = 0;
foreach $name (sort readdir(DIRHANDLE)) {
    if (!($name =~ m/^\./)) {
        @installed_apps[$count] = $name;
        $count++;
    }
}
closedir(DIRHANDLE);

if ($opt_debug) {
    printf STDERR "======= INSTALLED APPS =====\n";
    foreach $app (@installed_apps) {
        print STDERR "$app\n";
    }
    print STDERR "============================\n";
}

# read in list of required apps, from check list

open(CHECKLIST, "< $opt_list") || die("can't open $opt_list: $!");
$count = 0;
while(($name = <CHECKLIST>)) {
    chop($name);
    if (!($name =~ m/^\#/)) {
        @required_apps[$count] = $name;
        $count++;
    }
}
close(CHECKLIST);

if ($opt_debug) {
    printf STDERR "======= REQUIRED APPS =====\n";
    foreach $app (@required_apps) {
        print STDERR "$app\n";
    }
    print STDERR "============================\n";
}

# find apps which are not installed

$nmiss = 0;
foreach $req_app (@required_apps) {
    $found = 0;
    foreach $inst_app (@installed_apps) {
        if ($inst_app eq $req_app) {
            $found = 1;
            break;
        }
    }
    if (!$found) {
        @missing_apps[$nmiss] = $req_app;
        $nmiss++;
    }
}

# if apps are missing, print out error message

if ($nmiss > 0) {
    printf STDERR "=================>> ERROR <<===================\n";
    printf STDERR "====>> INCOMPLETE TITAN APP INSTALLATION <<====\n";
    printf STDERR "$nmiss missing applications:\n";
    foreach $mapp (@missing_apps) {
        printf STDERR "  $mapp missing\n";
        $findstr = `find apps -name $mapp`;
        @lines = split(/\n/, $findstr);
        printf STDERR "  Check in dir:\n";
        foreach $line (@lines) {
          printf STDERR "    $line\n";
        }
    }
    exit 1;
} else {
    printf STDERR "==================>> SUCCESS <<====================\n";
    printf STDERR "====>> ALL TITAN APPS SUCCESSFULLY INSTALLED <<====\n";
    exit 0;
}
