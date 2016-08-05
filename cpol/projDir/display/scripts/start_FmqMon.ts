#! /bin/csh -f

#xterm -title RadMon_S -bg black -fg cyan -g 74x3-0+0 -e "ssh cpolserver RadMon -params projDir/display/params/RadMon.cpol " &

RadMon -fmq ~/projDir/data/fmq/moments/shmem_20000 -summary -update -1



