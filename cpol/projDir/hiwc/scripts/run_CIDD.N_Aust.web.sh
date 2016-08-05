#! /bin/sh
# Start up CIDD

#***************************************
#
# run CIDD unmapped to produce web output
# (Note. rjp 7 Dec 2007 - For new code (titan5.4) running on Centos4 do not use
# option '-u') 
#
#**************************************

debug=1

if [ $debug==1 ] 
then
  echo "==== LdataWatcher script - $prog ====\n"
  echo "==== Running CIDD to generate images from the merged data ====\n"
fi

# Ensure virtual X server is running and set display accordingly. 
start_Xvfb
DISPLAY=':101.0';
export DISPLAY;
echo DISPLAY: $DISPLAY;

#xdpyinfo;

#CIDD -p $PROJ_DIR/radars/N_Aust/params/CIDD.N_Aust.web -u &
#CIDD -p $PROJ_DIR/radars/N_Aust/params/CIDD.N_Aust.web &
CIDD -p $PROJ_DIR/radars/N_Aust/params/CIDD.N_Aust.web  2>&1 | \
   LogFilter -d $ERRORS_LOG_DIR -p CIDD -i N_Aust.web & 

exit 0;

