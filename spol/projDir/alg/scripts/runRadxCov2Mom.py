#!/usr/bin/env python

#===========================================================================
#
# Run RadxCov2Mom for specified time interval
#
#===========================================================================

import os
import sys
import subprocess
from optparse import OptionParser
import datetime
from datetime import timedelta

def main():

    global options
    global scriptName
    scriptName = "runRadxCov2Mom"
    
    # parse the command line

    usage = "usage: %prog [options]"
    parser = OptionParser(usage)
    parser.add_option('--debug',
                      dest='debug', default='False',
                      action="store_true",
                      help='Set debugging on')
    parser.add_option('--verbose',
                      dest='verbose', default='False',
                      action="store_true",
                      help='Set verbose debugging on')
    parser.add_option('--paramsDir',
                      dest='paramsDir', default='/tmp/params',
                      help='Path of params directory')
    parser.add_option('--start',
                      dest='startTimeStr', default='2011 10 01 00 00 00',
                      help='String for start time, format dir: yyyy mm dd hh mm ss')
    parser.add_option('--end',
                      dest='endTimeStr', default='2012 01 16 00 00 00',
                      help='String for end time, format dir: yyyy mm dd hh mm ss')
    parser.add_option('--deltaTimeSecs',
                      dest='deltaTimeSecs', default='3600',
                      help='Delta time in secs')

    (options, args) = parser.parse_args()
    
    if (options.verbose == True):
        options.debug = True

    # get start and end times

    startTimeList = options.startTimeStr.split(" ")
    if (len(startTimeList) != 6):
        print >>sys.stderr, "ERROR - %s" % scriptName
        print >>sys.stderr, "  Start time format: yyyy mm dd hh mm ss, and remember to put it in quotes"
        exit(1)
        
    startYear = int(startTimeList[0])
    startMonth = int(startTimeList[1])
    startDay = int(startTimeList[2])
    startHour = int(startTimeList[3])
    startMinute = int(startTimeList[4])
    startSecond = int(startTimeList[5])

    endTimeList = options.endTimeStr.split(" ")
    if (len(endTimeList) != 6):
        print >>sys.stderr, "ERROR - %s" % scriptName
        print >>sys.stderr, "  End time format: yyyy mm dd hh mm ss, and remember to put it in quotes"
        exit(1)
        
    endYear = int(endTimeList[0])
    endMonth = int(endTimeList[1])
    endDay = int(endTimeList[2])
    endHour = int(endTimeList[3])
    endMinute = int(endTimeList[4])
    endSecond = int(endTimeList[5])

    startTime = datetime.datetime(startYear, startMonth, startDay,
                                  startHour, startMinute, startSecond)
    endTime = datetime.datetime(endYear, endMonth, endDay,
                                endHour, endMinute, endSecond)
    deltaTime = datetime.timedelta(0, int(options.deltaTimeSecs))
    
    # print out running state
    
    if (options.debug == True):
        print >>sys.stderr, "Running %s:" % scriptName
        print >>sys.stderr, "  params dir: ", options.paramsDir
        print >>sys.stderr, "  Start time: ", startTime
        print >>sys.stderr, "  End time: ", endTime
        print >>sys.stderr, "  deltaTimeSecs: ", options.deltaTimeSecs
        print >>sys.stderr, "  deltaTime: ", deltaTime

    # change directory to params dir

    os.chdir(options.paramsDir)

    # loop through time periods

    intvlStartTime = startTime
    intvlEndTime = intvlStartTime + deltaTime

    while (intvlEndTime <= endTime + deltaTime):
        print >>sys.stderr, "  Intvl start time: ", intvlStartTime
        print >>sys.stderr, "  Intvl end time: ", intvlEndTime
        runConv(intvlStartTime, intvlEndTime)
        intvlStartTime = intvlStartTime + deltaTime
        intvlEndTime = intvlStartTime + deltaTime
        
        
    sys.exit(0)

########################################################################
# Read in the directory list

def runConv(startTime, endTime):

    # set up time args
    
    startArg = (" -start \"%.4d %.2d %.2d %.2d %.2d %.2d\" " %
                (startTime.year, startTime.month, startTime.day,
                 startTime.hour, startTime.minute, startTime.second))
    
    endArg = (" -end \"%.4d %.2d %.2d %.2d %.2d %.2d\" " %
              (endTime.year, endTime.month, endTime.day,
               endTime.hour, endTime.minute, endTime.second))

    # sband
    
    cmd = "RadxCov2Mom -params RadxCov2Mom.sband.sur -debug " + \
          startArg + endArg
    runCommand(cmd)
    
    cmd = "RadxCov2Mom -params RadxCov2Mom.sband.rhi -debug " + \
          startArg + endArg
    runCommand(cmd)
    
    # kband
    
    cmd = "RadxCov2Mom -params RadxCov2Mom.kband.sur -debug " + \
          startArg + endArg
    runCommand(cmd)
    
    cmd = "RadxCov2Mom -params RadxCov2Mom.kband.rhi -debug " + \
          startArg + endArg
    runCommand(cmd)

    # clutter
    
    cmd = "RadxConvert -params RadxConvert.clut.sur -debug " + \
          startArg + endArg
    runCommand(cmd)
    
    cmd = "RadxConvert -params RadxConvert.clut.rhi -debug " + \
          startArg + endArg
    runCommand(cmd)
    
    # merge
    
    cmd = "RadxMergeFields -params RadxMergeFields.sur -debug " + \
          startArg + endArg
    runCommand(cmd)

    cmd = "RadxMergeFields -params RadxMergeFields.rhi -debug " + \
          startArg + endArg
    runCommand(cmd)

########################################################################
# Run a command in a shell, wait for it to complete

def runCommand(cmd):

    if (options.debug == True):
        print >>sys.stderr, "running cmd:",cmd
    
    try:
        retcode = subprocess.call(cmd, shell=True)
        if retcode < 0:
            print >>sys.stderr, "Child was terminated by signal: ", -retcode
        else:
            if (options.debug == True):
                print >>sys.stderr, "Child returned code: ", retcode
    except OSError, e:
        print >>sys.stderr, "Execution failed:", e

########################################################################
# Run - entry point

if __name__ == "__main__":
   main()
