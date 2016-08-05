#! /bin/csh

# start XVFB

#/$PROJ_DIR/radars/N_Aust/scripts/start_Xvfb9
$PROJ_DIR/system/scripts/start_Xvfb

# set up display environment

setenv DISPLAY :101.0

# run CIDD

CIDD -p $PROJ_DIR/radars/N_Aust/params/CIDD.N_Aust.web -u &







