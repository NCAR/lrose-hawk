#!/bin/sh

# wget Manitou NIDAS raw_data files from the RAL server.
# run statsproc on them and create the web plots

# set -x

renice +20 -p $$ > /dev/null

script=$0
script=${script##*/}

tmpdir=/scr/tmp/maclean/projects/$PROJECT

# logdir=$ISFF/projects/$PROJECT/ISFF/logs
logdir=$tmpdir/logs
[ -d $logdir ] || mkdir -p $logdir
[ -d $tmpdir/dnld ] || mkdir -p $tmpdir/dnld

cd $tmpdir

# url=http://rap.ucar.edu/projects/beachon/sites/turbulence-tower
url=http://beachon.rap.ucar.edu/projects/beachon/sites/turbulence-tower

for try in 1 2; do

    # first try to get a listing of the raw_data directory
    wget --quiet --load-cookies logs/cookies.txt -o logs/raw_data.log -O dnld/raw_data.http $url/file_download.php\?dir=raw_data

    # if what is returned does not contain the string 'File Download", then 
    # we probably need to login.  Don't know RAL's timeout on these sessions.
    if [ $try == 1 ] && ! fgrep -q "File Download" dnld/raw_data.http; then
        # user, password only, max-redirect. (Does fail if password is not correct)
        # If the URL ends in "restricted/login.php", then we get in a redirect loop.
        # If the URL ends in "restricted/" we don't get redirects. However, then
        # the file_download wget fails.
        # Don't know how to avoid these redirect loops
        echo "logging in again..."
        wget --quiet --keep-session-cookies --save-cookies logs/cookies.txt --user=fluxtower --password='l0tzoFD@t' -o logs/login.log -O dnld/login.http --max-redirect=1 $url/restricted/login.php
    fi
done

urls=(`sed -nr '/File:/s/^.*href="download.php\?[0-9a-f&]*file=([^"]+).*$/\1/p' dnld/raw_data.http`)
sizes=(`sed -nr '/Size:/s/^.*Size: *([0-9]+).*$/\1/p' dnld/raw_data.http`)

export DATAMNT=/scr/isfs
export DATADIR=raw_data
export DATA_SUFFIX="dat"
export RAWDATADIR=$DATAMNT/projects/$PROJECT/$DATADIR
cd $RAWDATADIR || exit 1

files=()
for (( i = 0; i < ${#urls[*]}; i++ )); do
    u=${urls[$i]}

    # convert %2F to /
    f=`echo $u | sed s,%2F,/,g`
    # remove leading directory (raw_data)
    f=${f##*/}

    # skip file names starting with a dot, which are in the process of being rsync'd
    [[ $f =~ "^\." ]] && continue
    # also skip 2009 files which we know are complete (and have been bzip2'd)
    [[ $f =~ ^manitou_2009 ]] && continue
    [[ $f =~ ^manitou_2010 ]] && continue
    [[ $f =~ ^manitou_20110[1-7] ]] && continue
    # echo $f

    s=${sizes[$i]}
    fok=false

    # compare file size on local directory against what was
    # in the downloaded listing.
    s2=0
    if [ -f $f ]; then
        s2=`ls -l $f | awk '{print $5}'`
        [ $s -eq $s2 ] && fok=true
    fi
    if ! $fok; then
        echo "fetching $f: size=$s, local size=$s2"
        wget --load-cookies $logdir/cookies.txt --no-verbose $url/download.php\?file=$u -O $f
        chmod -w $f
        files=(${files[*]} $f)
    fi
done

# Make a list of the files that should be processed.
# We have a list of the files that were just downloaded.
# We'll also use a timestamp file for the time of the last
# successful statsproc run.

# rhel5 find doesn't support -newerXY find options
if [ -e $logdir/.last.covar ]; then
    files=(${files[*]} `find . -regextype posix-extended -type f -regex "./manitou.*[0-9]{8}_[0-9]{6}.dat" -newer $logdir/.last.covar -print | sed s,^\./,,`)
else
    files=(${files[*]} `find . -regextype posix-extended -type f -regex "./manitou.*[0-9]{8}_[0-9]{6}.dat" -mtime -7 -print | sed s,^\./,,`)
fi

[ ${#files[*]} -eq 0 ] && exit 0

touch $logdir/.last.covar.tmp

# Do a unique sort of the names
# Use this IFS trick to put a newline between each file name, which
# allows sed and sort to work. Could just use a for loop too...
oldifs=$IFS
IFS=$'\n'
files=(`echo "${files[*]}" | sort -u`)
ymds=(`echo "${files[*]}" | sed -rn 's,[^_]+_([0-9]{8})_[0-9]{6}.dat,\1,p' | sort -u`)
IFS=$oldifs

export QC_DIR=QC
export SONIC_DIR=boom_normal
export NETCDF_DIR=netcdf_field

webnetcdf=/net/www/docs/isf/projects/$PROJECT/isfs/netcdf
[ -d $webnetcdf ] || mkdir -p $webnetcdf

[ -d $ISFF/projects/$PROJECT/ISFF/$NETCDF_DIR ] || \
    mkdir -p $ISFF/projects/$PROJECT/ISFF/$NETCDF_DIR

statsproc ${files[*]} || exit 1
mv $logdir/.last.covar.tmp $logdir/.last.covar

rsync -a $ISFF/projects/$PROJECT/ISFF/$NETCDF_DIR/. $webnetcdf

# Formal way to determine which plots contain a given sample:
# For a given time $t there will be a 48 hour web plot
# centered at tplot= utime -L $t +"%Y %m %d 12:00"   (noon local of given day)
# if $t > $tplot then that sample will also be in a plot centered at $tplot + 86400
# if $t < $tplot then that sample will also be in a plot centered at $tplot - 86400
plottimes() {
    local t=$1
    [ $t -lt $(utime 2009 7 8 00:00) ] && return
    local tplot=`utime -l $(utime -L $t +"%Y %m %d 12:00")`
    if [ $t -lt $tplot ]; then
        echo $(($tplot - 86400))
        echo $tplot
    else
        echo $tplot
        echo $(($tplot + 86400))
    fi  
}

# loop over the file date strings
# Using the date from a file name, get the plottimes for
# 00:00 and 24:00 UTC (assume we get all 24 hours of the UTC date).
times=(`for ymd in ${ymds[*]}; do
    tymd=$(utime $ymd +%Y%m%d +)
    plottimes $tymd
    plottimes $(($tymd + 86400))
done | sort -u`)

for td in ${times[*]}; do
    echo "doing: webplots `utime -L $td +'%Y %m %d'`"
    webplots `utime -L $td +'%Y %m %d'`
done

bdisk=/media/isff1
if [ -d $bdisk ]; then
    if ! [ -d $bdisk/projects/$PROJECT ]; then
        mount $bdisk
        mkdir -p $bdisk/projects/$PROJECT || exit 1
    fi
    rsync -a ${RAWDATADIR} $bdisk/projects/$PROJECT
fi

rsync_ntpstat.sh

