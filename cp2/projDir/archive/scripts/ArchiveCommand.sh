#!/bin/bash

# ArchiveCommand.sh
# 20100129kg - Used to be called Archive3ExtDisk.sh

# Script to backup radar data to external hard disk.
# Version 2 - includes desired param files plus simplified archive rsync calls (more wildcard use)
#
# 20100129 Adapted for better Archive Delete processing and logging.  Also renamed to ArchiveCommand.sh
# 20081112 Added Archival of Disdrometer data - disdrometer & disdroSubs added kg
# ~20081009 Calibration subs (calSubs) added - now includes vert & tunig directory
# 20081007 sat added to mdv subs for CSRP2 - All sat/*/yyyymmdd will be archived - kg
#

EX=`/bin/basename $0`
EXloc=`/usr/bin/dirname $0`
E="/bin/echo -e"
ERR=ERROR
EN="/bin/echo -ne"
L=$E
started_as=`$E "[Started As:] $EX $@"`
started_in=$EXloc
testARCMD="$E [test] rsync -avl"
realARCMD="rsync -avl"
ARCMD=$realARCMD
testARCMDQUIET="$E [test] rsync -a"
realARCMDQUIET="rsync -al"
ARCMDQUIET=$realARCMDQUIET
testTARCMD="$E [test] tar cvfz"
realTARCMD="tar cvfz"
TARCMD=$realTARCMD
testTARCMDQUIET="$E [test] tar cfz"
realTARCMDQUIET="tar cfz"
TARCMDQUIET=$realTARCMDQUIET
testRMCMD="$E [test] /bin/rm -rfv"
realRMCMD="/bin/rm -rfv"
RMCMD=$testRMCMD
SUDOpwFile=$EXloc/titan5pw
defaultLogName=Archive

cmd_mode="ARCHIVING"	# Is set to DELETING for '-c delete' mode

#  
dataroot=/raid/data/titan5/data
logroot=$dataroot/logs/archive
# datarootskycam=/raid/data
# disdrometer added 20081112 KG
archdirlist="calibration logs mdv rapic soundings spdb sunscan titan raw skycam disdrometer"
bomradars="BrisMerge Grafton Kanign Marburg Moree MtStapl"
cp2_sx="cp2_s cp2_x"

# The following are the first level subdirectories of those in archdirlist above that need to be handled
# Each has it's own default archive behaviour.  Those that have to be handled specially need their own archive
# definitions
calSubs="tuning vert"
logSubs="distrib errors restart archive"
#mdvSubs="precip radarPolar radarCart derived terrain vil"
# sat added for CSRP2 - All sat/*/yyyymmdd will be archived - 20081007 kg
mdvSubs="precip radarPolar radarCart sat terrain vil"
rapicSubs="rapicdb"
spdbSubs="ac_posn ascii_ac_posn aws ltg rhi tstorms tstorms_xml"
sunSubs="$cp2_sx"
titanSubs="storms"
# mcidasNcf (McIdas NetCDF data) added 20081007 kg
rawSubs="aws ltg mcidasNcf sunscan"
skycamSubs="cp2 ybbn ybcg"
# disdroSubs added 20081112 KG
disdroSubs="BoM_RD80 2dvddata NCAR_Data"
BoM_RD80_Prefix="CSRP2-"
BoM_2dvd_Prefix="V"
NCAR_Data_Prefix="200"

declare -i diskavailstart
declare -i useDiskSize useLastWrote useSpaceLeft useMaxPerDay useThisDay tmpSize usePercent useTemp1 useTemp2 tmpInt
declare -i useLastDeleted 

# Amend default start date to '20081001' - 20081007 kg
declare -i startdate=20081001
# Out - default is 1 day now 20081007kg:# declare -i enddate=`/bin/date -u +%Y%m%d`
declare -i curday curmon curyear curjulday month
declare -ai leapmonthdays=(0 31 29 31 30 31 30 31 31 30 31 30 31)
declare -ai monthdays=(0 31 28 31 30 31 30 31 31 30 31 30 31)

isleapyear () {
	local year=`$E $1 | cut -c 1-4 -`
	[[ ( $(($year%4)) -eq 0 && $(($year%100)) -ne 0 ) || $(($year%400)) -eq 0 ]]
}

calcjulday() {
	curjulday=0
	month=1
	if isleapyear $curyear
	then
		while [ $month -lt $curmon ]
		do
			((curjulday+=${leapmonthdays[month]}))
			#$E month=$month, curjulday=$julday
			((month++))
		done
	else
		while [ $month -lt $curmon ]
		do
			((curjulday+=${monthdays[month]}))
			#$E month=$month, curjulday=$julday
			((month++))
		done
	fi
	((curjulday+=$curday))
}

setcurdate () {
	curdate=$1
	curyear=$(echo $curdate | cut -c 1-4 -)
	curmon=10#$(echo $curdate | cut -c 5-6 -)
	curday=10#$(echo $curdate | cut -c 7-8 -)
	shortdate=`$E $curdate | cut -c 3- -`
	calcjulday
	curjuldate=`printf "%04d%03d" $curyear $curjulday`
	shortjuldate=`$E $curjuldate | cut -c 3- -`

}

incrementdate () {
	if isleapyear $curyear
	then
		[[ $((++curday)) -gt ${leapmonthdays[curmon]} ]] && { curday=1; ((curmon++)); }
	else
		[[ $((++curday)) -gt ${monthdays[curmon]} ]] && { curday=1; ((curmon++)); }
	fi
	[[ $curmon -gt 12 ]] && { curmon=1; ((curyear++)); }
	newdate=`printf "%04d%02d%02d" $curyear $curmon $curday`
	setcurdate $newdate
	#$E "Increment Date: $curdate($shortdate) := $curyear $curmon $curday, juldate: $curjuldate($shortjuldate)"
}

ERROR() {
	$L "$EX: ERROR - $@" >&2
	useStatus="ERROR"
}

EXIT_ERROR() {
	ERROR "$@"
	$E "[$EX: EXITING]" >&2
	[ ! -z "$usagefile" ] && writeDiskUsage
	exit 1
}

logfunc() {
	$E -e `/bin/date +%Y%m%d_%H%M.%S`: "$@"
}

toGb() {
	tmpInt=$1+52428
	useTemp1=$tmpInt/1048576
	useTemp2=$tmpInt%1048576
	useTemp2=$useTemp2%1048576/104857
	useTempGb="${useTemp1}.${useTemp2}G"
}

readDiskUsage() {
	# Expects a Usage parameter file ($usagefile) to be readable.
	# If not, will fill with params from the system or defaults.
	# Will check that params in the file compare to the physical disk and report discrepencies
	# Reads and sets Variables:
	#    useDiskLabel	  text
	#    useFirstDate  yyyymmdd
	#    useLastDate  yyyymmdd
	#    useEnded     yyyymmdd_hhmm.ss
	#    useLastWrote     int(Kb)  [text GB]
	#    useDiskSize      int(Kb)  [text GB]
	#    useSpaceLeft     int(Kb)  [text GB]
	#    useMaxPerDay     int(Kb)  [text GB]
	#	 useStatus		  OK | WRITING | FULL | ERROR | NEW_DISK

	#$E "readDiskUsage(): usagefile = $usagefile"

	if ( [ ! -z "$usagefile" ] && [ -e $usagefile ] )
	then
		if [ -r "$usagefile" ]
		then
			useDiskLabel=`grep "DiskLabel:" $usagefile | perl -e '{ @line=split ( /\s+/,<>); print "@line[1]"; }' -`
			useFirstDate=`grep "FirstDate:" $usagefile | perl -e '{ @line=split ( /\s+/,<>); print "@line[1]"; }' -`
			useStarted=`grep "StartedAt:" $usagefile | perl -e '{ @line=split ( /\s+/,<>); print "@line[1]"; }' -`
			useLastDate=`grep "LastDate:" $usagefile | perl -e '{ @line=split ( /\s+/,<>); print "@line[1]"; }' -`
			useEnded=`grep "EndedAt:" $usagefile | perl -e '{ @line=split ( /\s+/,<>); print "@line[1]"; }' -`
			useLastWrote=`grep "LastWrote:" $usagefile | perl -e '{ @line=split ( /\s+/,<>); print "@line[1]"; }' -`
			useLastDeleted=`grep "LastDeleted:" $usagefile | perl -e '{ @line=split ( /\s+/,<>); print "@line[1]"; }' -`
			useDiskSize=`grep "DiskSize:"   $usagefile | perl -e '{ @line=split ( /\s+/,<>); print "@line[1]"; }' -`
			useSpaceLeft=`grep "SpaceLeft:" $usagefile | perl -e '{ @line=split ( /\s+/,<>); print "@line[1]"; }' -`
			useMaxPerDay=`grep "MaxPerDay:" $usagefile | perl -e '{ @line=split ( /\s+/,<>); print "@line[1]"; }' -`
		else
			ERROR "readDiskUsage() - Unable to read usage file: $usagefile"
		fi
	elif [ ! -z "$usagefile" ]
	then
		[ "$logging" = true ] && ERROR "readDiskUsage() - 'usagefile': $usagefile is Missing or not Accessible"
		useStatus="NEW_DISK"
	fi

	if [ -z "$useDiskLabel" ] 
	then
		[ "$logging" = true ] && $E "Usage File: Missing Disk Label - Using '$disklabel'"
		useDiskLabel=$disklabel
	fi
	tmpSize=`/bin/df | grep $diskdev | perl -e '{ @line=split ( /\s+/,<>); print "@line[1]"; }' -`
	if [ -z "$useDiskSize" ]
	then
		[ "$logging" = true ] && toGb $tmpSize && $E "Usage File: Missing DiskSize detail - Using: '$tmpSize  [$useTempGb]'"
		useDiskSize=$tmpSize
	fi
	if [ $useDiskSize -ne $tmpSize ]
	then
		toGb $tmpSize
		[ "$logging" = true ] && $E "Usage File: Disk DiskSize MISS-MATCH - Usage-File=$useDiskSize - Setting to $tmpSize  [$useTempGb]"
		useSpaceLeft=$tmpSize
	fi
	tmpSize=`/bin/df | grep $diskdev | perl -e '{ @line=split ( /\s+/,<>); print "@line[3]"; }' -`
	if [ -z "$useSpaceLeft" ]
	then
		[ "$logging" = true ] && toGb $tmpSize && $E "Usage File: Missing Disk SpaceLeft detail - Using: '$tmpSize  [$useTempGb]'"
		useSpaceLeft=$tmpSize
	fi
	if [ $useSpaceLeft -ne $tmpSize ]
	then
		toGb $tmpSize
		[ "$logging" = true ] && $E "Usage File: Disk SpaceLeft MISS-MATCH - Usage-File=$useSpaceLeft - Setting to $tmpSize  [$useTempGb]"
		useSpaceLeft=$tmpSize
	fi

}

# Function to write the Disk Usage information (either to useagfile or to stdout)
# If passed a param - will use this at the useStatus string.
writeDiskUsage() {
	if [ ! -z "$usagefile" ]
	then
		/bin/touch $usagefile || ERROR "Unable to write (touch) usagefile: $usagefile..."
	else
		usagefile=/dev/stdout
	fi
	[ $# -ne 0 ] && useStatus=$1
	[ -z "$useThisDay" ] && useThisDay=0
	[ -z "$useMaxPerDay" ] && useMaxPerDay=0

	[ "$useStatus" = "WRITING" ] && startedAction=`/bin/date +%Y%m%d_%H%M.%S`
	[ "$useStatus" = "DELETING" ] && startedAction=`/bin/date +%Y%m%d_%H%M.%S`

	if [ -w $usagefile ]
	then
		$E "$EX: Archive Disk Usage Statistics" > $usagefile
		$E "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" >> $usagefile
		[ ! -z "$useDiskLabel" ] && $E "DiskLabel:\t$useDiskLabel" >> $usagefile
		if [ $useThisDay -ne 0 ]
		then
			[ -z "$useFirstDate" ] && useFirstDate=$curdate
			[[ $curdate -lt $useFirstDate ]] && useFirstDate=$curdate
			[ -z "$useStarted" ] && [ ! -z "$startedAction" ] && useStarted=$startedAction
			[ -z "$useLastDate" ] && useLastDate=$curdate
			[[ $curdate -gt $useLastDate ]] && useLastDate=$curdate
			useEnded=`/bin/date +%Y%m%d_%H%M.%S`
		fi
		if [ $useThisDay -gt 0 ]
		then
			useLastWrote=$useThisDay
		elif [ $useThisDay -lt 0 ]
		then
			useLastDeleted=0-$useThisDay	
			useThisDay=$useLastDeleted
		fi 
		[ ! -z "$useFirstDate" ] && $E "FirstDate:\t$useFirstDate" >> $usagefile
		[ ! -z "$useStarted" ] && $E "StartedAt:\t$useStarted" >> $usagefile
		[ ! -z "$useLastDate" ] && $E "LastDate:\t$useLastDate" >> $usagefile
		[ ! -z "$useEnded" ] && $E "EndedAt:\t$useEnded" >> $usagefile
		[ ! -z "$useLastWrote" ] && toGb $useLastWrote && $E "LastWrote:\t$useLastWrote\t[$useTempGb]" >> $usagefile
		[ ! -z "$useLastDeleted" ] && toGb $useLastDeleted && $E "LastDeleted:\t$useLastDeleted\t[$useTempGb]" >> $usagefile

		tmpSize=`/bin/df | grep $diskdev | perl -e '{ @line=split ( /\s+/,<>); print "@line[1]"; }' -`
		[ $useDiskSize -ne $tmpSize ] && \
			{ $E " writeDiskUsage: DiskSize MISS-MATCH - was $useDiskSize - Setting to $tmpSize"; useDiskSize=$tmpSize; useStatus=ERROR; }
		[ ! -z "$useDiskSize" ] && toGb $useDiskSize && $E "DiskSize:\t$useDiskSize\t[$useTempGb]" >> $usagefile
		tmpSize=`/bin/df | grep $diskdev | perl -e '{ @line=split ( /\s+/,<>); print "@line[3]"; }' -`
		[ ! $del_mode ] && [ $useSpaceLeft -ne $tmpSize ] && \
			{ $E " writeDiskUsage: SpaceLeft MISS-MATCH - was $useSpaceLeft - Setting to $tmpSize"; useSpaceLeft=$tmpSize; useStatus=ERROR; }
		[ ! -z "$useSpaceLeft" ] && toGb $useSpaceLeft && $E "SpaceLeft:\t$useSpaceLeft\t[$useTempGb]" >> $usagefile
		[ $useThisDay -gt $useMaxPerDay ] && useMaxPerDay=$useThisDay
		[ $useMaxPerDay -ne 0 ] && toGb $useMaxPerDay && $E "MaxPerDay:\t$useMaxPerDay\t[$useTempGb]" >> $usagefile
		[ ! -z "$useStatus" ] && $E "Status:\t\t$useStatus" >> $usagefile

	else
		ERROR "writeDiskUsage() - Unable to create usage file: $usagefile"
	fi
	[ $usagefile = "/dev/stdout" ] && unset usagefile
}

USAGE() {
        cat << EOF_USAGE

Usage: $EX [options...] 
Archives CP2 Radar data to an attached external Disk Drive
Disk must be connected and mounted and accessible r/w.

Uses rsync so that re-issuing the command will not re-write all data already copied to disk

Specify the disk mount point with '-d /disk/mount/dir'  (eg: -d /media/CP2archiveA)

Options:
  -d dir      : Disk Mount Directory
  -s yyyymmdd : Set the archive START date (defaults to start of data taken for CSRP2 [20081001])
  -e yyyymmdd : Set the archive END   date (default is to archive 1 day being START date)
  -n ndays    : Set the archive END date such that ndays from start date are archived
  -c delete   : Change to Delete Archive Data Mode - *** WILL DELETE DATA if followed by '-c real' ***
  -c real     : Change to Delete Archive Data Mode - *** WILL CAUSE REAL DELETE OF DATA ***
  -c test     : Activate 'test' mode - will echo cammands that will be executed but not actually do them
  -l          : Turns on Logging output to Logfile.  
              : Logfile is placed in $dataroot/logs/archive. Logfile Name 
  -h	      : Print this message

EOF_USAGE
}

unset del_mode
while getopts "d:s:e:n:hlc:?" c
do
        case $c in
          d)    diskroot=$OPTARG;;
          s)    startdate=$OPTARG;;
          e)    enddate=$OPTARG;;
		  n)	ndays=$OPTARG;;
		  c)	command=$OPTARG
				case $command in
				   delete )
						CMD_MODE="DELETING"
						del_mode=true
				   ;;
				   real )
						ARCMD=$realARCMD
						ARCMDQUIET=$realARCMDQUIET
						TARCMD=$realTARCMD
						TARCMDQUIET=$realTARCMDQUIET
				   		if [ $del_mode ]
						then
							RMCMD=$realRMCMD
							$E "WARNING: You have selected options to DELETE files!"
							$EN "Do you want to continue (YES to confirm)? "
							read reply
							[ "$reply" != "YES" ] && EXIT_ERROR "Script Exited..."
						fi
				   ;;
				   test )
						ARCMD=$testARCMD
						ARCMDQUIET=$testARCMDQUIET
						TARCMD=$testTARCMD
						TARCMDQUIET=$testTARCMDQUIET
						RMCMD=$testRMCMD
				   ;;
				   * )
						EXIT_ERROR "Invalid Command supplied:  '-c $command'\n '-c delete|real|test' are the only valid args for command mode"
				   ;;
				esac
				;;
		  l)	L=logfunc
		  		logging=true
				;;
          h | ?)  	USAGE
                exit 2;;
        esac
done
shift `/usr/bin/expr $OPTIND - 1`

# In delete mode Give this a dummy arg:
[ $del_mode ] && diskroot=$dataroot

if [ -z "$diskroot" ]
then
    ERROR "No Disk mount point supplied - use -d option..."
	USAGE
	exit 3
fi

curhostname=`/bin/hostname | perl -e '{ @line=split ( /\./,<>); print "@line[0]"; }' -`
today_dt=`/bin/date +%Y%m%d_%H%M`
diskroottail=`$EN $diskroot | perl -e '{ @line=split ( /\//,<>) ; print"@line[$#line]" ; }' -`
[ -z "$diskroottail" ] && { ERROR "'$diskroot' - Does not appear to ba a valid file system (No '/'s in it)!"; exit 1; }
diskrootroot=`$EN $diskroot | perl -e '{ @line=split ( /\//,<>) ; print"@line[1]" ; }' -`
$E "curhostname=$curhostname   today_dt=$today_dt  diskrootroot=$diskrootroot  diskroottail=$diskroottail"
if [ $del_mode ]
then
	diskdev=`/bin/df | grep $diskrootroot | perl  -e '{ @line=split ( / /,<>); print "@line[0]"; }' -`
else
	diskdev=`/bin/df | grep $diskroottail | perl  -e '{ @line=split ( / /,<>); print "@line[0]"; }' -`
fi
[ -z "$diskdev" ] && { ERROR "'$diskroot' - is not a mounted disk"; exit 1; }
if [ $del_mode ]
then
	disklabel=${curhostname}_$defaultLogName
else
	disklabel=`sudo -S /sbin/e2label $diskdev <  $SUDOpwFile | /usr/bin/tail -n1 2>/dev/null`
fi
[ -z "$disklabel" ] && disklabel=$defaultLogName

diskavailstart=`/bin/df | grep $diskdev | perl  -e '{ @line=split ( /\s+/,<>); print "@line[3]"; }' -`
diskavailstartgb=`/bin/df -h | grep $diskdev | perl  -e '{ @line=split ( /\s+/,<>); print "@line[3]"; }' -`

if [ "$logging" = true ]
then
	if [ $del_mode ]
	then
		logfile=${logroot}/${curhostname}_archive_delete_${today_dt}.log
		errorfile=${logroot}/${curhostname}_archive_delete_${today_dt}.error
		usagefile=${logroot}/${curhostname}_archive_delete_${today_dt}.usage
	else
		logfile=$logroot/$disklabel.log
		errorfile=$logroot/$disklabel.error
		usagefile=$logroot/$disklabel.usage
	fi
	[ ! -e $logfile ] && /bin/touch $logfile || EXIT_ERROR "Can't Create logfile: $logfile"
	[ ! -e $errorfile ] && /bin/touch $errorfile || EXIT_ERROR "Can't Create errorfile: $errorfile"
	[ ! -e $usagefile ] && /bin/touch $usagefile || EXIT_ERROR "Can't Create usagefile: $usagefile"
	$E "$EX: Logging: logfile=$logfile\n$EX: errors: errorfile=$errorfile\n$EX: Usage: usagefile=$usagefile"

	exec 6>&1		# Link fd #6 to stdout (Saves stdout)
	exec 1>>$logfile || EXIT_ERROR "Unable to open $logfile for log output"
	#exec 7>&1		# Link fd #7 to stderr (Saves stderr)
	#exec 2>>$errorfile || { ERROR "Unable to open $errorfile for error output" && exit 1; }
fi

$E "*************************************************************************************"
$L $started_as
#$L $started_in

#$E "del_mode=$del_mode    diskroot=$diskroot"
[ ! $del_mode ] && [ ! -d $diskroot -o ! -w $diskroot ] && \
		{ ERROR "'$diskroot' - Destination Missing or not Writeable"; exit 1; }
destloc=$diskroot/data

if [ -z "$enddate" -a -z "$ndays" ]
then
	ndays="1"
fi

if [ ! -z "$ndays" ]
then
	[[ $ndays -le 0 ]] && ndays=1
	ndaystext=" (ndays=$ndays)"
	setcurdate $startdate
	while [ $((--ndays)) -gt 0 ]; do incrementdate; done
	enddate=$curdate
fi	

[[ $startdate -gt $enddate ]] && \
		{ ERROR "$EX: Start Date ($startdate) > End Date ($enddate)"; exit 1; }

#$E "$EX: EXloc=$EXloc"
$L "Data Root Directory (dataroot) is $dataroot"
$L "Archive Disk Location is: $diskroot  ($diskroottail) mounted on [$diskdev] labelled [$disklabel]" 
$L "Archive Directory list is '$archdirlist'"
$L " Start Date = '$startdate' ... End Date = '$enddate' $ndaystext"
$L " Archive Disk Stats: Disk Space Available: $diskavailstart K ($diskavailstartgb)"

#ERROR "Testing ERROR() function......."

# Set error output to errorfile now - want to see errors on stderr till now!
if [ "$logging" = true ]
then
	exec 7>&1		# Link fd #7 to stderr (Saves stderr)
	exec 2>>$errorfile || EXIT_ERROR "Unable to open $errorfile for error output."
	#ERROR "Logging errors to $errorfile now......."
fi

[ ! $del_mode ] && readDiskUsage

setcurdate $startdate

#ERROR "Testing ERROR() function......."
#$E "curdate: $curdate($shortdate) := $curyear $curmon $curday, juldate: $curjuldate($shortjuldate)"
#exit

OkToContinue=true
[ $curdate -gt $enddate ] && OkToContinue=false
[ ! "$OkToContinue" = true ] && $E "Date Range At/Past End Date: $curdate > $enddate"
[ -z "$useThisDay" ] && useThisDay=0
[ -z "$MaxUsePerDay" ] && MaxUsePerDay=0
useSpaceLeft=`/bin/df | grep $diskdev | perl -e '{ @line=split ( /\s+/,<>); print "@line[3]"; }' -`
[ $useMaxPerDay -ne 0 ] && [ $useSpaceLeft -lt $useMaxPerDay ] && OkToContinue=false
[ ! "$OkToContinue" = true ] && $E "Disk Usage: NO SPACE ON DISK. Usage Per Day = $useMaxPerDay, Space on Disk = $useSpaceLeft"

while [ "$OkToContinue" = true ]
do
	$E
	$E "+++++++++++++ $CMD_MODE Date: $curdate ++++++++++++++++"

	if [ $del_mode ]
	then
		writeDiskUsage "DELETING"
	else
		writeDiskUsage "WRITING"
	fi

	for dir in $archdirlist
	do
		$E "
		============= Directory: $dir ==============="
		case $dir in
		  calibration )
			for subdir in $calSubs
			do
				$E " '->>>>>>>>> Sub-Directory: $dir/$subdir >>>>>>>>>>"
				[ ! -d $dataroot/$dir/$subdir ] && $E "     ***** NO DATA *****"
				[ ! $del_mode ] && [ -d $dataroot/$dir/$subdir ] && $ARCMD $dataroot/$dir/$subdir $destloc
				[ $del_mode ] && [ -d $dataroot/$dir/$subdir ] && $E "  ***** We Do Not DELETE $dir Data *****"
			done
			;;
		  logs ) 
			for subdir in $logSubs
			do
				case $subdir in 
				  archive )
					$E " '->>>>>>>>> Sub-Directory: $dir/$subdir/ ($curdate) >>>>>>>>>>"
					[ ! -d $dataroot/$dir/$subdir ] && $E "     ***** ERROR!!! NO DATA *****"
					[ ! $del_mode ] && [ -d $dataroot/$dir ] && mkdir -p $destloc/$dir && $ARCMD $dataroot/$dir/$subdir $destloc/$dir
				  	;;
				  * )
					$E " '->>>>>>>>> Sub-Directory: $dir/$subdir/$curdate >>>>>>>>>>"
					[ ! -d $dataroot/$dir/$subdir/$curdate ] && $E "     ***** NO DATA *****"
					[ ! $del_mode ] && [ -d $dataroot/$dir/$subdir/$curdate ] && \
							mkdir -p $destloc/$dir/$subdir && $ARCMD $dataroot/$dir/$subdir/$curdate $destloc/$dir/$subdir
					[ $del_mode ] && [ -d $dataroot/$dir/$subdir/$curdate ] && $E "  ***** We Do Not DELETE $dir Data *****"
					;;
				esac
			done
			;;
		  mdv )
			for subdir in $mdvSubs
			do
				case $subdir in 
				  precip )
					for arpath in 1hr 24hr single
					do
						$E " '->>>>>>>>> Sub-Directory: $dir/$subdir/$arpath/$curdate/ >>>>>>>>>>"
						[ ! -d $dataroot/$dir/$subdir/$arpath/$curdate ] && $E "     ***** NO DATA *****"
						[ ! $del_mode ] && [ -d $dataroot/$dir/$subdir/$arpath/$curdate ] && mkdir -p $destloc/$dir/$subdir/$arpath && \
								$ARCMD $dataroot/$dir/$subdir/$arpath/$curdate $destloc/$dir/$subdir/$arpath
						[ $del_mode ] && [ -d $dataroot/$dir/$subdir/$arpath/$curdate ] && \
								$RMCMD $dataroot/$dir/$subdir/$arpath/$curdate
					done
					;;
				  radarPolar )
					for arpath in $cp2_sx derived
					do
						for scan in rhi sec sur vert
						do
							$E " '->>>>>>>>> Sub-Directory: $dir/$subdir/$arpath/$scan/$curdate/ >>>>>>>>>>"
							[ ! -d $dataroot/$dir/$subdir/$arpath/$scan/$curdate ] && $E "     ***** NO DATA *****"
							[ ! $del_mode ] && [ -d $dataroot/$dir/$subdir/$arpath/$scan/$curdate ] && mkdir -p $destloc/$dir/$subdir/$arpath/$scan && \
									$ARCMD $dataroot/$dir/$subdir/$arpath/$scan/$curdate $destloc/$dir/$subdir/$arpath/$scan
							unset do_Ar; for file in $dataroot/$dir/$subdir/$arpath/$scan/_Ds*; do [ -f $file ] && do_Ar=true; done
							[ ! $del_mode ] && [ $do_Ar ] && $ARCMD $dataroot/$dir/$subdir/$arpath/$scan/_Ds* $destloc/$dir/$subdir/$arpath/$scan
							[ $del_mode ] && [ -d $dataroot/$dir/$subdir/$arpath/$scan/$curdate ] && \
									$RMCMD $dataroot/$dir/$subdir/$arpath/$scan/$curdate
						done
					done
					for arpath in $bomradars
					do
						$E " '->>>>>>>>> Sub-Directory: $dir/$subdir/$arpath/$curdate/ >>>>>>>>>>"
						[ ! -d $dataroot/$dir/$subdir/$arpath/$curdate ] && $E "     ***** NO DATA *****"
						[ ! $del_mode ] && [ -d $dataroot/$dir/$subdir/$arpath/$curdate ] && mkdir -p $destloc/$dir/$subdir/$arpath && \
								$ARCMD $dataroot/$dir/$subdir/$arpath/$curdate $destloc/$dir/$subdir/$arpath
						[ $del_mode ] && [ -d $dataroot/$dir/$subdir/$arpath/$curdate ] && \
								$RMCMD $dataroot/$dir/$subdir/$arpath/$curdate
					done
					;;
				  radar* )
					for arpath in $bomradars
					do
						$E " '->>>>>>>>> Sub-Directory: $dir/$subdir/$arpath/$curdate/ >>>>>>>>>>"
						[ ! -d $dataroot/$dir/$subdir/$arpath/$curdate ] && $E "     ***** NO DATA *****"
						[ ! $del_mode ] && [ -d $dataroot/$dir/$subdir/$arpath/$curdate ] && mkdir -p $destloc/$dir/$subdir/$arpath && \
								$ARCMD $dataroot/$dir/$subdir/$arpath/$curdate $destloc/$dir/$subdir/$arpath
						[ $del_mode ] && [ -d $dataroot/$dir/$subdir/$arpath/$curdate ] && \
								$RMCMD $dataroot/$dir/$subdir/$arpath/$curdate
					done
					;;
				  sat )
					satSubs=`cd $dataroot/mdv/sat/; ls -d *`
					for arpath in $satSubs
					do
						$E " '->>>>>>>>> Sub-Directory: $dir/$subdir/$arpath/$curdate/ >>>>>>>>>>"
						[ ! -d $dataroot/$dir/$subdir/$arpath/$curdate ] && $E "     ***** NO DATA *****"
						[ ! $del_mode ] && [ -d $dataroot/$dir/$subdir/$arpath/$curdate ] && mkdir -p $destloc/$dir/$subdir/$arpath && \
								$ARCMD $dataroot/$dir/$subdir/$arpath/$curdate $destloc/$dir/$subdir/$arpath
						[ $del_mode ] && [ -d $dataroot/$dir/$subdir/$arpath/$curdate ] && \
								$RMCMD $dataroot/$dir/$subdir/$arpath/$curdate
					done
					;;
				  vil )
					for arpath in $bomradars
					do
						$E " '->>>>>>>>> Sub-Directory: $dir/$subdir/$arpath/$curdate/ >>>>>>>>>>"
						[ ! -d $dataroot/$dir/$subdir/$arpath/$curdate ] && $E "     ***** NO DATA *****"
						[ ! $del_mode ] && [ -d $dataroot/$dir/$subdir/$arpath/$curdate ] && mkdir -p $destloc/$dir/$subdir/$arpath && \
								$ARCMD $dataroot/$dir/$subdir/$arpath/$curdate $destloc/$dir/$subdir/$arpath
						[ $del_mode ] && [ -d $dataroot/$dir/$subdir/$arpath/$curdate ] && \
								$RMCMD $dataroot/$dir/$subdir/$arpath/$curdate
					done
					;;
				  terrain )
					$E " '->>>>>>>>> Sub-Directory: $dir/$subdir/terrain >>>>>>>>>>"
					[ ! -d $dataroot/$dir/$subdir ] && $E "     ***** NO DATA *****"
					[ ! $del_mode ] && [ -d $dataroot/$dir/$subdir ] && mkdir -p $destloc/$dir && $ARCMD $dataroot/$dir/$subdir $destloc/$dir
					unset do_Ar; for file in $dataroot/$dir/$subdir/_Ds*; do [ -f $file ] && do_Ar=true; done
					[ ! $del_mode ] && [ $do_Ar ] && $ARCMD $dataroot/$dir/$subdir/_Ds* $destloc/$dir/$subdir
					;;
				  * )
					EXIT_ERROR "######### Need to set up Archive for Subdirectory: $dir/$subdir  #########\g"
					;;
				esac 
			done
			;;
		  rapic )
			for subdir in $rapicSubs
			do
				case $subdir in 
				  rapicdb )
					$E " '->>>>>>>>> Sub-Directory: $dir/$subdir/ ($curdate) >>>>>>>>>>"
					unset do_Ar; for file in $dataroot/$dir/$subdir/${shortdate}*; do [ -f $file ] && do_Ar=true; done
					[ ! $do_Ar ] && $E "     ***** NO DATA *****"
					[ ! $del_mode ] && [ $do_Ar ] && mkdir -p $destloc/$dir/$subdir && \
							$ARCMD $dataroot/$dir/$subdir/$shortdate* $destloc/$dir/$subdir
					[ $del_mode ] && [ $do_Ar ] && $RMCMD $dataroot/$dir/$subdir/$shortdate*
					;;
				  * )
					EXIT_ERROR "######### Need to set up Archive for Subdirectory: $dir/$subdir  #########\g"
					;;
				esac 
			done
		  	;;
		  soundings )
			$E "  '->>>>>>>> Raw Soundings for $curdate >>>>>>>>>>"
		  	soundingdate=`printf "%04d_%02d_%02d" $curyear $curmon $curday`
			unset do_Ar; for file in $dataroot/$dir/${soundingdate}*; do [ -f $file ] && do_Ar=true; done
			[ ! $do_Ar ] && $E "     ***** NO ROOT-DIR DATA *****"
			[ ! $del_mode ] && [ $do_Ar ] && mkdir -p $destloc/$dir && $ARCMD $dataroot/$dir/$soundingdate* $destloc/$dir
			[ $del_mode ] && [ $do_Ar ] && $RMCMD $dataroot/$dir/$soundingdate*
			$E " '->>>>>>>>> Sub-Directory: $dir/$curdate/ >>>>>>>>>>" && \
			[ ! -d $dataroot/$dir/$curdate ] && $E "     ***** NO DATA *****"
			[ ! $del_mode ] && [ -d $dataroot/$dir/$curdate ] && mkdir -p $destloc/$dir && $ARCMD $dataroot/$dir/$curdate $destloc/$dir
			[ $del_mode ] && [ -d $dataroot/$dir/$curdate ] && $RMCMD $dataroot/$dir/$curdate
			;;
		  spdb )
			for subdir in $spdbSubs
			do
				case $subdir in 
				  rhi )
					for arpath in $cp2_sx
					do
						$E " '->>>>>>>>> Sub-Directory: $dir/$subdir/$arpath ($curdate) >>>>>>>>>>"
						[ ! -f $dataroot/$dir/$subdir/$arpath/${curdate}.data ] && $E "     ***** NO DATA *****"
						if [ -f $dataroot/$dir/$subdir/$arpath/${curdate}.data ] && [ ! $del_mode ]
						then
							mkdir -p $destloc/$dir/$subdir/$arpath && \
								$ARCMD $dataroot/$dir/$subdir/$arpath/$curdate* $destloc/$dir/$subdir/$arpath
							unset do_Ar; for file in $dataroot/$dir/$subdir/$arpath/_*Symprod*; do [ -f $file ] && do_Ar=true; done
							[ $do_Ar ] && $ARCMD $dataroot/$dir/$subdir/$arpath/_*Symprod* $destloc/$dir/$subdir/$arpath
						elif [ -f $dataroot/$dir/$subdir/$arpath/${curdate}.data ] && [ $del_mode ]
						then
							$RMCMD $dataroot/$dir/$subdir/$arpath/$curdate*
						fi
					done
					;;
				  tstorms* )
					for arpath in $bomradars 
					do
						$E " '->>>>>>>>> Sub-Directory: $dir/$subdir/$arpath/ ($curdate) >>>>>>>>>>"
						[ ! -f $dataroot/$dir/$subdir/$arpath/${curdate}.data ] && $E "     ***** NO DATA *****"
						if [ -f $dataroot/$dir/$subdir/$arpath/${curdate}.data ] && [ ! $del_mode ]
						then
							mkdir -p $destloc/$dir/$subdir/$arpath && \
								$ARCMD $dataroot/$dir/$subdir/$arpath/$curdate* $destloc/$dir/$subdir/$arpath
							unset do_Ar; for file in $dataroot/$dir/$subdir/$arpath/_*Symprod*; do [ -f $file ] && do_Ar=true; done
							[ $do_Ar ] && $ARCMD $dataroot/$dir/$subdir/$arpath/_*Symprod* $destloc/$dir/$subdir/$arpath
						elif [ -f $dataroot/$dir/$subdir/$arpath/${curdate}.data ] && [ $del_mode ]
						then
							$RMCMD $dataroot/$dir/$subdir/$arpath/$curdate*
						fi
					done
					;;
				  * )
					$E " '->>>>>>>>> Sub-Directory: $dir/$subdir/ ($curdate) >>>>>>>>>>"
					[ ! -f $dataroot/$dir/$subdir/${curdate}.data ] && $E "     ***** $dataroot/$dir/$subdir/${curdate}.data - NO DATA *****"
					if [ -f $dataroot/$dir/$subdir/${curdate}.data ] && [ ! $del_mode ]
					then
						mkdir -p $destloc/$dir/$subdir && $ARCMD $dataroot/$dir/$subdir/$curdate* $destloc/$dir/$subdir
						unset do_Ar; for file in $dataroot/$dir/$subdir/_*Symprod*; do [ -f $file ] && do_Ar=true; done
						[ $do_Ar ] && $ARCMD $dataroot/$dir/$subdir/_*Symprod* $destloc/$dir/$subdir
					elif [ -f $dataroot/$dir/$subdir/${curdate}.data ] && [ $del_mode ]
					then
						$RMCMD $dataroot/$dir/$subdir/$curdate*
					fi
					;;
				esac 
			done
			;;
		  sunscan )
			for subdir in $sunSubs 
			do
				$E " '->>>>>>>>> Sub-Directory: $dir/$subdir/$curdate/ >>>>>>>>>>"
				[ $del_mode ] && $E "   ***** We Do Not DELETE $dir data *****"
				[ ! $del_mode ] && [ ! -d $dataroot/$dir/$subdir/$curdate ] && $E "     ***** NO DATA *****"
				[ ! $del_mode ] && [ -d $dataroot/$dir/$subdir/$curdate ] && mkdir -p $destloc/$dir/$subdir && \
						$ARCMD $dataroot/$dir/$subdir/$curdate $destloc/$dir/$subdir
			done
		  	;;
		  titan )
			for subdir in $titanSubs
			do
				case $subdir in 
				  storms )
					for arpath in $bomradars 
					do
						$E " '->>>>>>>>> Sub-Directory: /$dir/$subdir/$arpath/ ($curdate) >>>>>>>>>>"
						unset do_Ar; for file in $dataroot/$dir/$subdir/$arpath/*${curdate}*; do [ -f $file ] && do_Ar=true; done
						[ ! $do_Ar ] && $E "     ***** NO DATA *****"
						[ ! $del_mode ] && [ $do_Ar ] && mkdir -p $destloc/$dir/$subdir/$arpath && \
								$ARCMD $dataroot/$dir/$subdir/$arpath/$curdate* $destloc/$dir/$subdir/$arpath
						[ $del_mode ] && [ $do_Ar ] && $RMCMD $dataroot/$dir/$subdir/$arpath/$curdate*
					done
					;;
				  * )
					EXIT_ERROR "  ######### Need to set up Archive for Subdirectory: $dir/$subdir  #########\g"
					;;
				esac 
			done
		  	;;
		  raw )
			for subdir in $rawSubs
			do
				case $subdir in 
				  sunscan )
					for arpath in $cp2_sx
					do
						$E " '->>>>>>>>> Sub-Directory: $dir/$subdir/$arpath ($curdate) >>>>>>>>>>"
						unset do_Ar; for file in $dataroot/$dir/$subdir/$arpath/*${curdate}*; do [ -f $file ] && do_Ar=true; done
						[ ! $do_Ar ] && $E "     ***** NO DATA *****"
						[ ! $del_mode ] && [ $do_Ar ] && mkdir -p $destloc/$dir/$subdir/$arpath && \
								$ARCMD $dataroot/$dir/$subdir/$arpath/*${curdate}* $destloc/$dir/$subdir/$arpath
						[ $del_mode ] && [ $do_Ar ] && \
								$ARCMD $dataroot/$dir/$subdir/$arpath/*${curdate}*
					done
					;;
				  * )
					$E " '->>>>>>>>> Sub-Directory: $dir/$subdir/$curdate >>>>>>>>>>"
					[ ! -d $dataroot/$dir/$subdir$curdate ] && $E "     ***** NO DATA *****"
					[ ! $del_mode ] && [ -d $dataroot/$dir/$subdir/$curdate ] && \
							mkdir -p $destloc/$dir/$subdir && $ARCMD $dataroot/$dir/$subdir/$curdate $destloc/$dir/$subdir
					[ $del_mode ] && [ -d $dataroot/$dir/$subdir/$curdate ] && \
							$RMCMD $dataroot/$dir/$subdir/$curdate
					;;
				esac 
			done
		  	;;
		  skycam ) 
			for subdir in $skycamSubs
			do
				case $subdir in 
				  cp2 )
					$E " '->>>>>>>>> Sub-Directory: $dir/$subdir/$curdate >>>>>>>>>>"
					[ ! -d $dataroot/$dir/$subdir/$curdate ] && $E "     ***** NO DATA *****"
					[ ! $del_mode ] && [ -d $dataroot/$dir/$subdir/$curdate ] && \
							mkdir -p $destloc/$dir/$subdir && $ARCMD $dataroot/$dir/$subdir/*.html $destloc/$dir/$subdir
					[ ! $del_mode ] && [ -d $dataroot/$dir/$subdir/$curdate ] && \
							$E " Copying all files in '$dir/$subdir/$curdate' to $destloc/$dir/$subdir" && \
							$E "  -> $ARCMDQUIET $dataroot/$dir/$subdir/$curdate $destloc/$dir/$subdir" && \
							$ARCMDQUIET $dataroot/$dir/$subdir/$curdate $destloc/$dir/$subdir
					[ $del_mode ] && [ -d $dataroot/$dir/$subdir/$curdate ] && \
							$E " Deleting all files in '$dir/$subdir/$curdate'" && \
							$RMCMD $dataroot/$dir/$subdir/$curdate
					;;
				  * )
					$E " '->>>>>>>>> Sub-Directory: $dir/$subdir/$curdate >>>>>>>>>>"
					[ ! -d $dataroot/$dir/$subdir/$curdate ] && $E "     ***** NO DATA *****"
					[ ! $del_mode ] && [ -d $dataroot/$dir/$subdir/$curdate ] && \
							$E " Tar(gz)'ing all files in '$dir/$subdir/$curdate' to $destloc/$dir/$subdir" && \
							$E "  -> $TARCMDQUIET $destloc/$dir/$subdir/${subdir}_${curdate}.tgz -C $dataroot/$dir/$subdir $curdate" && \
							mkdir -p $destloc/$dir/$subdir && \
							$TARCMDQUIET $destloc/$dir/$subdir/${subdir}_${curdate}.tgz -C $dataroot/$dir/$subdir $curdate
					[ $del_mode ] && [ -d $dataroot/$dir/$subdir/$curdate ] && \
							$E " Deleting all files in '$dir/$subdir/$curdate'" && \
							$RMCMD $dataroot/$dir/$subdir/$curdate
					;;
				esac 
			done
			;;
		  disdrometer )
			for subdir in $disdroSubs 
			do
				case $subdir in 
				  BoM_RD80 )
					$E " '->>>>>>>>> Sub-Directory: $dir/$subdir/ ($curdate) >>>>>>>>>>"
					unset do_Ar; for file in $dataroot/$dir/$subdir/${BoM_RD80_Prefix}${shortdate}*; do [ -f $file ] && do_Ar=true; done
					[ ! $do_Ar ] && $E "     ***** NO DATA *****"
					[ ! $del_mode ] && [ $do_Ar ] && mkdir -p $destloc/$dir/$subdir && \
							$ARCMD $dataroot/$dir/$subdir/${BoM_RD80_Prefix}${shortdate}* $destloc/$dir/$subdir && \
							$ARCMD $dataroot/$dir/$subdir/${BoM_RD80_Prefix}BoM*.txt $destloc/$dir/$subdir
					[ $del_mode ] && [ $do_Ar ] && $RMCMD $dataroot/$dir/$subdir/${BoM_RD80_Prefix}${shortdate}*
					;;
				  2dvddata )
					for arpath in ab2 hyd raw sno
					do
						$E " '->>>>>>>>> Sub-Directory: $dir/$subdir/$arpath ($curdate => $shortjuldate) >>>>>>>>>>"
						unset do_Ar; for file in $dataroot/$dir/$subdir/$arpath/${BoM_2dvd_Prefix}${shortjuldate}*; do [ -f $file ] && do_Ar=true; done
						[ ! $do_Ar ] && $E "     ***** NO DATA *****"
						[ ! $del_mode ] && [ $do_Ar ] && mkdir -p $destloc/$dir/$subdir/$arpath && \
								$ARCMD $dataroot/$dir/$subdir/$arpath/${BoM_2dvd_Prefix}${shortjuldate}* $destloc/$dir/$subdir/$arpath && \
								$ARCMD $dataroot/$dir/$subdir/*.txt $destloc/$dir/$subdir
						[ $del_mode ] && [ $do_Ar ] && $RMCMD $dataroot/$dir/$subdir/${BoM_2dvd_Prefix}${shortjuldate}*
					done
					;;
				  NCAR_Data )
					for arpath in Level_1
					do
						$E " '->>>>>>>>> Sub-Directory: $dir/$subdir/$arpath/${NCAR_Data_Prefix}$curdate/ >>>>>>>>>>"
						[ ! -d $dataroot/$dir/$subdir/$arpath/${NCAR_Data_Prefix}$curdate ] && $E "     ***** NO DATA *****"
						[ ! $del_mode ] && [ -d $dataroot/$dir/$subdir/$arpath/${NCAR_Data_Prefix}$curdate ] && \
								mkdir -p $destloc/$dir/$subdir/${NCAR_Data_Prefix}$arpath && \
								$ARCMD $dataroot/$dir/$subdir/$arpath/${NCAR_Data_Prefix}$curdate $destloc/$dir/$subdir/$arpath && \
								$ARCMD $dataroot/$dir/$subdir/*.txt $destloc/$dir/$subdir
						[ $del_mode ] && [ -d $dataroot/$dir/$subdir/$arpath/${NCAR_Data_Prefix}$curdate ] && \
								$RMCMD $dataroot/$dir/$subdir/$arpath/${NCAR_Data_Prefix}$curdate
					done
					;;
				  * )
					EXIT_ERROR "  ######### Need to set up Archive for Subdirectory: $dir/$subdir  #########\g"
					;;
				esac 
			done
		  	;;
		esac
	done
	
	# Adjust Disk Usage Stuff:

	tmpSize=`/bin/df | grep $diskdev | perl -e '{ @line=split ( /\s+/,<>); print "@line[3]"; }' -`
	useThisDay=$useSpaceLeft-$tmpSize
	useSpaceLeft=$tmpSize

	if ( [ ! -z "$useMaxPerDay" ] && [ $useMaxPerDay -ne 0 ] && [ $useSpaceLeft -lt $useMaxPerDay ] ) 
	then
		OkToContinue=false
		writeDiskUsage "FULL"
		$E "$disklabel: Is FULL"
		[ "$logging" = true ] && $E "$disklabel: Is FULL" 
	else
		writeDiskUsage "OK"
	fi
	
	incrementdate
	$E "Next Date: $curdate($shortdate) := $curyear $curmon $curday, juldate: $curjuldate($shortjuldate)"
	useThisDay=0

	if ( [ "$OkToContinue" = true ] && [ $curdate -gt $enddate ] )
	then
		OkToContinue=false
		$E "Selected Date At/Past End Date: $curdate > $enddate"
	fi
done
	
# Close any output redirections:
if [ "$logging" = true ]
then
	# Close the output redirections
	exec 1>&6 6>&-
	exec 2>&7 7>&-
fi

$E " '->>>>>>>>> Updating The Archive Log to the ext Disk: logs/archive/ >>>>>>>>>>"
[ ! -d $dataroot/$dir/$subdir ] && $E "     ***** ERROR!!! NO LOG DATA *****"
[ ! $del_mode ] && [ -d $dataroot/logs ] && $ARCMD $dataroot/logs/archive $destloc/logs
[ ! $del_mode ] && [ -d $logroot ] && $ARCMD $logroot/$disklabel.usage $destloc
