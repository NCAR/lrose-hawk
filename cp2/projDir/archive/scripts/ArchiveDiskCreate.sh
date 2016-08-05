#!/bin/bash

# ArchiveDiskCreate.sh
#
#   Script to automate the process of creating a new CP2 Radar Archive Disk Drive
#   Archive Disks are currently an externally housed 500GB SATAII Hard disk - attached either
#   to an ESATA port or to a USB port (either is usable)


EX=`/bin/basename $0`
E=/bin/echo
EN="/bin/echo -n"

#  
defaultbase="cp2archive"	# Base of the Disk Label to be created

declare -i startdate=20071027
declare -i enddate=`date -u +%Y%m%d`
declare -i curday curmon curyear
declare -ai leapmonthdays=(0 31 29 31 30 31 30 31 31 30 31 30 31)
declare -ai monthdays=(0 31 28 31 30 31 30 31 31 30 31 30 31)

isleapyear () {
	local year=`$E $1 | cut -c 1-4 -`
	[[ ( $(($year%4)) -eq 0 && $(($year%100)) -ne 0 ) || $(($year%400)) -eq 0 ]]
}

setcurdate () {
	curdate=$1
	curyear=$(echo $startdate | cut -c 1-4 -)
	curmon=10#$(echo $startdate | cut -c 5-6 -)
	curday=10#$(echo $startdate | cut -c 7-8 -)
}

incrementdate () {
	if isleapyear $curyear
	then
		[[ $((++curday)) -gt ${leapmonthdays[curmon]} ]] && { curday=1; ((curmon++)); }
	else
		[[ $((++curday)) -gt ${monthdays[curmon]} ]] && { curday=1; ((curmon++)); }
	fi
	[[ $curmon -gt 12 ]] && { curmon=1; ((curyear++)); }
	curdate=`printf "%04d%02d%02d" $curyear $curmon $curday`
}

USAGE() {
        cat << EOF_USAGE

Usage: $EX [options...] 
Runs the commands required to create a new CP2 Archive Disk
Disk must be connected and accessible.
You must pass the relevant disk /dev device id with the -d option below plus the -n Sequence 
number and -c Sub Sequence Char.

Steps performed are:
1. Disk is checked that it is connected and is suitable for use. 
   It is expected that the disk will be new/blank and without partitions
2. the whole Disk set up with one partition with an msdos Label
3. An ext3 filesystem is created on this partition
4. the disk is named/labled using e2label - using 'diskbasenam'+'_'+'majornum'+'minorchar'
5. The disk is made Read/Write to ALL ready for archive data to be written to it


Options:
  -d /dev/disk : /dev/sdx Disk Device File to use to create the disk on
  -m NEXT-MODE : where NEXT-MODE is one of 'set', 'seq', 'major' or 'minor'
               : Next - specifies to how to increment to the next Archive Disk Number.
			   : set: Sets the minor & major components as supplied by -n & -c opts
			   :      If either ommitted then the stored value from the last disk is used.
			   : seq: automatically choose the next logical label. The logic here is to
			   :      increment the minor char (a,b or c), and increment the major number
			   :      when at minor exceeds 'c' and go back to 'a'.
			   : major: Increment to the next 'major' number - resets minor to 'a'
			   : minor: Increment the minor char through the sequence 'a', 'b', 'c'
			   : Default: NEXT-MODE='seq'
  -b basename  : Sets the string to be used as the basename in its label [default: last one used or 'cp2archive']
  -n Num       : Sets the Disk Sequence Number to be used for the 'majornum' in its label
               : this is normally the disk number which you would increment for each new disk
  -c Char      : Sets the Character to be used for the 'minorchar' in its label 
               : this Char is normally used to identify each copy of a particular disk if multiple
               : copies are required (eg. a=BoM, b=NCAR etc)
  -f           : Force - will force the creation of a new disk - OVERWRITING old partitions!
  -t type      : Set Partition type to create: ext3 [default], ext2
  -h	       : Print this message

Note: This script uses 'sudo' to perform super user tasks, so requires that the user is a permitted
      sudoer in /etc/sudoers.  It will also prompt the user for the current user password as per 
      normal sudo proctice. (see man sudo(8))

*** WARNING: this process will re-format/re-partition a disk so has the potential to be DANGEROUS

EOF_USAGE
}

nextmode="seq"

while getopts d:m:b:n:c:ft:h c
do
        case $c in
          d)    diskdev=$OPTARG;;
          m)    nextmode=$OPTARG;;
          b)    labelbasename=$OPTARG;;
          n)    majornum=$OPTARG;;
	  	  c)	minorchar=$OPTARG;;
	  	  f)	force=true;;
	  	  t)	parttype=$OPTARG;;
          *)  	USAGE
                exit 2;;
        esac
done
shift `/usr/bin/expr $OPTIND - 1`

[ -d ~/projDir/logs/archive ] || { mkdir -p ~/projDir/logs/archive  || \
	{ $E "$EX: Unable to create Log Dir:  ~/projDir/logs/archive"; exit 1; }; }
[ $HOSTNAME = "cp2server.bom.gov.au" ] || \
	scp cp2server.bom.gov.au:~/projDir/logs/archive/LastCreatedDiskLabel.txt ~/projDir/logs/archive
[ -f ~/projDir/logs/archive/LastCreatedDiskLabel.txt ] && LastDiskLabel=`tail -1 ~/projDir/logs/archive/LastCreatedDiskLabel.txt`
$E LastDiskLabel=$LastDiskLabel

if [ -z "$diskdev" ]
then
    $E "$EX: No Disk /dev/sd? supplied - use -d option..."
	exit 1
fi

lastbase=`$EN $LastDiskLabel | perl -e '{ @line=split ( /_/,<>) ; print"@line[0]" ; }' -`
lastminor=`$EN $LastDiskLabel | perl -e '{ @line=split ( /_/,<>) ; $minor=substr(@line[1],-1); print"$minor" ; }' -`
lastmajor=`$EN $LastDiskLabel | perl -e '{ @line=split ( /_/,<>) ; $major=substr(@line[1],0,-1); print"$major" ; }' -`
#$E labelbasename=$labelbasename  lastbase=$lastbase
#$E minorchar=$minorchar 	lastminor=$lastminor
#$E majornum=$majornum 	lastmajor=$lastmajor
#$E nextmode=$nextmode

# Setup labelbasename:
[ -z "$labelbasename" -a -z "$lastbase" ] && labelbasename=$defaultbase
[ -z "$labelbasename" ] && labelbasename=$lastbase

[ -z "$minorchar" -a -z "$lastminor" ] && \
    $E "$EX: WARNING: No Disk Minor Char supplied [-cChar]  This will default to 'a'.." && minorchar="a"

[ -z "$majornum" -a -z "$lastmajor" ] && \
    $E "$EX: No Disk Major Sequence Number supplied [-n#] nor available... exiting" && exit 1

case "$nextmode" in
  set)  
		# We want to respect any settings provided with the -n & -c command line params and not increment them
		# But, if they are not provided we will do the standard increment of the last minor - folding to the major
  		if [ ! -z "$majornum" -o ! -z "$minorchar" ]
		then
			[ -z "$majornum" ] && majornum=$lastmajor
			[ -z "$minorchar" ] && minorchar=`$E $lastminor | perl -e '{  $minornum=chr(ord(<>)+1); print "$minornum"; }' -`
		else
			minorchar=`$E $lastminor | perl -e '{  $minornum=chr(ord(<>)+1); print "$minornum"; }' -`
			majornum=$lastmajor
		fi
		tested="$($E $minorchar | sed -e 's/[abc]//g')"
		[ "$minorchar" = "$tested" ] && minorchar="a" && let majornum=$lastmajor+1
  		;;
  seq | minor)
		# We want to accept any settings provided with the -n & -c command line params and will increment them.
		# But if not provided we will increment of the last minor - folding to the major
		# If one provided we will use it and grab the other from the last used....
		[ -z "$majornum" ] && majornum=$lastmajor
		[ -z "$minorchar" ] && minorchar=$lastminor
		minorchar="$($E $minorchar | perl -e '{  $minornum=chr(ord(<>)+1); print "$minornum"; }' -)"
		tested="$($E $minorchar | sed -e 's/[abc]//g')"
		[ "$minorchar" = "$tested" ] && minorchar="a" && let majornum=$lastmajor+1
  		;;
  major)
  		[ ! -z "$majornum" ] && let majornum=$majornum+1
  		[ -z "$majornum" ] && let majornum=$lastmajor+1
		[ -z "$minorchar" ] && minorchar="a"
  		;;
  *)
  		$E "$EX: ERROR - Invalid option passed for '-n NEXT-MODE' ==> '-n $nextmode'"
		exit 1
  		;;
esac

case "$parttype" in
  ext2 | ext3 )  
  		$E "Manually overriding partition type to: $parttype"
		[ "$parttype" = "ext3" ] && mke2fsopt="-j"
  		;;
  *)
		[ ! -z "$parttype" ] && $E "$EX: ERROR - Invalid option passed for '-t PART-TYPE' ==> '-t $parttype'" && exit 1
		parttype=ext3	# Default to ext3
  		;;
esac

labelname=${labelbasename}_${majornum}${minorchar}
$E "diskdev = $diskdev"
$E "Archive Disk Label will be: ${labelname}" 
$EN "Is this ok? (y or n) "
read reply; [ "$reply" != "y" ] && exit 2


$E "Making sure the drive is un-mounted using 'gnome-mount ...-u'"
sudo gnome-mount -nd ${diskdev}1 -u

# Check is any partitions exist on this disk - if so - we pull out!
sudo parted -s $diskdev "print 1" >/dev/null && [ "$force" != true ] && \
	{ $E "$EX: ABORTED!  $diskdev appears to have partitions! Please use -f to override or Remove them manually."; exit 1; } 
sudo parted -s $diskdev "print 1" >/dev/null && \
	{ $EN "WARNING: Disk has partition(s?) that will be forcefully (-f) removed.  Proceed? (y or n) "; read reply; [ "$reply" != "y" ] && exit 2; }

sudo parted -s $diskdev "mklabel msdos" >/dev/null || \
	{ $E "$EX: OOPS.... Unable to make the msdos partition label on $diskdev";  \
	$E "This will happen if the disk has been formatted before and is probably safe to skip....";  \
	$E -n "Do you want to skip this and continue (y/n)? "; read n; [ -z "$n" -o "$n" = "n" ] && exit 1; }

sleep 1
sudo parted -s $diskdev "mkpart primary $parttype 0 -0" >/dev/null || \
	{ $E "$EX: ABORTED!  Unable to create Partition on $diskdev"; exit 1; } 

sleep 1
# Check that the partition exists on this disk NOW - if not - we pull out!
sudo parted -s $diskdev "print 1" >/dev/null || \
	{ $E "$EX: ABORTED!  $diskdev creation of partition has failed!"; exit 1; } 

sleep 1
diskdevpart=${diskdev}1
$E "Making sure the drive is un-mounted using 'gnome-mount ...-u'"
sudo gnome-mount -nd ${diskdevpart} -u
sleep 1

# Make the File System on the new partition:
sudo mke2fs $mke2fsopt -L $labelname $diskdevpart || \
	{ $E "$EX: ABORTED!  Unable to make file system ('mke2fs -j -L $labelname $diskdevpart')!"; exit 1; } 

sleep 2

# *** DONE ABOVE *** 
# Put a ext2/ext3 label on the disk - This is used by the HAL mount daemon in use on CP2 systems to mount
# the disk at an appropriate place and with a suitable mount name.
#sudo e2label $diskdevpart $labelname || \
#	{ $E "$EX: ABORTED!  Unable label the file system ('e2label $diskdevpart $labelname')!"; exit 1; } 

# Now need to make the drive read/write by all:
[ -d /media/${labelbasename}_tmp ] || { sudo mkdir -p /media/${labelbasename}_tmp || \
	{ $E "$EX: Unable to create temp Mount Point: /media/${labelbasename}_tmp - Manual completion REQUIRED!"; exit 1; }; }
sudo mount $diskdevpart /media/${labelbasename}_tmp || \
	{ $E "$EX: Unable to Mount $diskdevpart at /media/${labelbasename}_tmp - Manual completion REQUIRED!"; exit 1; }
sudo chmod a+rw /media/${labelbasename}_tmp || \
	{ $E "$EX: Unable to 'chmod a+rw /media/${labelbasename}_tmp' - Manual completion REQUIRED!"; exit 1; }
sudo tune2fs $diskdevpart -i 0 -c -1 || \
	{ $E "$EX: FAILED 'tune2fs /media/${labelbasename}_tmp -i 0 -c -1' - Manual completion REQUIRED!"; exit 1; }
sudo umount /media/${labelbasename}_tmp || \
	{ $E "$EX: FAILED 'umount /media/${labelbasename}_tmp' - Manual completion REQUIRED!"; exit 1; }
sudo rmdir /media/${labelbasename}_tmp || \
	{ $E "$EX: FAILED 'rmdir /media/${labelbasename}_tmp' - Manual completion REQUIRED!"; exit 1; }

sleep 3

$E "Restarting the HAL Daemon to make sure the new drive is re-sacnned..."
sudo /etc/rc.d/init.d/haldaemon restart

sleep 2

$E "Mounting the new disk partition using 'gnome-mount'"
gnome-mount -d $diskdevpart

$E
$E $labelname >> ~/projDir/logs/archive/LastCreatedDiskLabel.txt

[ $HOSTNAME = "cp2server.bom.gov.au" ] || \
	scp ~/projDir/logs/archive/LastCreatedDiskLabel.txt cp2server.bom.gov.au:~/projDir/logs/archive
$E "$EX: Done - Disk '$labelname' is ready for use."


