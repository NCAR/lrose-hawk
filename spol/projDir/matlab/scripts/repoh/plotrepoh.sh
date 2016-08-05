#!/bin/bash

cd ${PROJ_DIR}/data/matlab/REPoH

for f in *.ascii

  do
  
  if [ -e $f ]
      then
      
      declare -a fname=($f)
      i=("${fname:0:8}")	#yyyymmdd
      year=("${fname:0:4}")     #yyyy
      month=("${fname:4:2}")	#mm
      day=("${fname:6:2}")	#dd
      j=("${fname:9:2}")	#hh
      k=("${fname:11:2}")	#mm
      
# remove leading 0 from month or day
      
      day=`echo $day|sed 's/^0*//'`
      month=`echo $month|sed 's/^0*//'`
      
      set today = `date --date='-1 day' +%Y%m%d`
      set tomorrow = `date --date='+1 day' +%Y%m%d`
      
#If after the half hour, then file goes with the next hour.
# This is so that hourly average can straddle time of DOE sounding.
      
      if [ "$k" -ge 31 ]; then
          if [ "$j" -lt 9 ]; then
              j=0$((10#$j+1))
          elif [ "$j" -eq 23 ]; then
              j=0$((10#$j-23))
    #WHAT ABOUT END OF MONTH/YEAR?
              if (( "$day" == 30 )) && \
                  (( "$month" == 4 || "$month" == 6 || "$month" == 9 || "$month" == 11 )) || \
                  (( "$day" == 31 )) || (( "$day" == 29 && "$month" == 2 )); then
                  
                  if [ "$month" -lt 9 ]; then
                      month=0$((10#$month+1))
                  elif [ "$month" -eq 10 || "$month" -eq 11 ]; then
                      month=$((10#$month+1))
                  else
                      month=0$((10#$month-11))
                      year=$((10#$year+1)) 
                  fi
              fi
          else
              j=$((10#$j+1))
          fi
      fi
      
      if [ ! -d $i ]; then
  #Make directory for each date.
          mkdir $i
          mkdir -p images/$i
      fi

      if [ ! -e $i'_hour'$j'.out' ]; then
          cat $f > $i'_hour'$j'.temp'
      else 
          cat $i'_hour'$j'.out' $f > $i'_hour'$j'.temp'
      fi

      mv $i'_hour'$j'.temp' $i'_hour'$j'.out'
      mv $f $i
      rm -f *.out
      
  fi

done
