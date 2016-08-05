#!/bin/bash

# ArchiveDelete.sh

# Script to backup radar data to external hard disk.
# Version 2 - includes desired param files plus simplified archive rsync calls (more wildcard use)
#

EX=`/bin/basename $0`
EXloc=`/usr/bin/dirname $0`
E="/bin/echo -e"
ERR=ERROR
EN="/bin/echo -ne"
L=$E
started_as=`$E "[Started As:] $EX $@"`
started_in=$EXloc

deleteCmd="ArchiveCommand.sh"
deleteExec="$EXloc/$deleteCmd -c delete -c real"
logging="-l"
dataroot=/raid/data/titan5/data

ERROR() {
	$L "$EX: ERROR - $@" >&2
	useStatus="ERROR"
}

EXIT_ERROR() {
	ERROR "$@"
	USAGE
	$E "[$EX: EXITING]" >&2
	exit 1
}

logfunc() {
	$E -e `/bin/date +%Y%m%d_%H%M.%S`: "$@"
}

USAGE() {
        cat << EOF_USAGE

Usage: $EX [options...] 
Delets CP2 Radar data from CP2 Archive Disks

Uses the ArchiveCommand.sh script to perform the actions.
For more control, use that manually.

Options:
  -s yyyymmdd : Set the archive START date (defaults to start of data taken for CSRP2 [20081001])
  -e yyyymmdd : Set the archive END   date (default is to archive 1 day being START date)
  -n ndays    : Set the archive END date such that ndays from start date are archived
  -l          : Turns OFF Logging output to Logfile. (Loggin ON by default)
              : Logfile is placed in $dataroot/logs/archive. Logfile Name 
  -h	      : Print this message

EOF_USAGE
}

while getopts "s:e:n:hl?" c
do
        case $c in
          s)    startdate="-s $OPTARG";;
          e)    enddate="-e $OPTARG";;
		  n)	ndays="-n $OPTARG";;
		  l)	logging=""
				;;
          h | ?)  	USAGE
                exit 2;;
        esac
done
shift `/usr/bin/expr $OPTIND - 1`

$E "*************************************************************************************"
$L $started_as
#$L $started_in

if [ -z "$enddate" -a -z "$ndays" ]
then
	ndays="-n 1"
fi

[ -z "$startdate" ] && EXIT_ERROR "Must pass a start date with -s..."

$deleteExec $startdate $enddate $ndays $logging

