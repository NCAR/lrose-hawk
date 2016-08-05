#! /bin/csh

set daystr=`date -u +%Y%m%d`
set daydir=${daystr}I1
set filename=${daystr}I1_iwg1.txt

while (1)

  \rm -rf ${filename}*

  wget http://flightscience.noaa.gov/pub/flight/aamps_ingest/iwg1/${daydir}/${filename}

  \cp ${filename} $DATA_DIR/raw/ac_posn/p3/${daystr}

  LdataWriter -dir $DATA_DIR/raw/ac_posn/p3 -dtype txt -ext txt -rpath ${daystr}/${filename}

  sleep 120

end

