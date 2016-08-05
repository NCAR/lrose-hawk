#! /bin/csh

set_font_path
setenv DATA_HOST cpolserver
cd $PROJ_DIR/display/params

CIDD -p CIDD.vert -i vert  |& \
    LogFilter -d $ERRORS_LOG_DIR -p CIDD -i vert &

