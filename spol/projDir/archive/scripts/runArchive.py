#!/usr/bin/env python

# ========================================================================== #
#
# Trigger the archive script
#
# ========================================================================== #

import os
import sys
from optparse import OptionParser
import time
import datetime
from datetime import date
from datetime import timedelta
import subprocess

def main():

    global options
    global dirList
    global driveList
    global deviceTable
    global labelTable

    # parse the command line

    usage = "usage: %prog [options]"
    parser = OptionParser(usage)
    parser.add_option('--debug',
                      dest='debug', default='False',
                      action="store_true",
                      help='Set debugging on')
    parser.add_option('--test',
                      dest='testMode', default='False',
                      action="store_true",
                      help='Use preset dates instead of today')
    parser.add_option('--source',
                      dest='sourceDir', default='/tmp/source',
                      help='Path of source directory')
    parser.add_option('--project',
                      dest='projectName', default='dynamo',
                      help='Name of project - used to generate target dir')
    parser.add_option('--primaryListPath',
                      dest='primaryListPath',
                      default='/tmp/primaryListPath',
                      help='Path to file containing primary directory list')
    parser.add_option('--secondaryListPath',
                      dest='secondaryListPath',
                      default='/tmp/secondaryListPath',
                      help='Path to file containing secondary directory list')

    (options, args) = parser.parse_args()

    if (options.debug == True):
        print >>sys.stderr, "Options:"
        print >>sys.stderr, "  Debug: ", options.debug
        print >>sys.stderr, "  Test mode: ", options.testMode
        print >>sys.stderr, "  Source dir: ", options.sourceDir
        print >>sys.stderr, "  Project name: ", options.projectName
        print >>sys.stderr, "  Primary dir list path: ", options.primaryListPath
        print >>sys.stderr, "  Secondary dir list path: ", options.secondaryListPath

    # compile the list of target drives

    compileDriveList()

    if (options.debug == True):
        for drive in driveList:
            print >>sys.stderr, \
                  "target drive, device, label: ", \
                  drive, deviceTable[drive], labelTable[drive]

    # compute day string for today
    # in test mode we set the daystr directly

    if (options.testMode == True):
        nowTime = time.strptime("20110425010000", "%Y%m%d%H%M%S")
    else:
        nowTime = time.gmtime()

    today = datetime.datetime(nowTime.tm_year, nowTime.tm_mon, nowTime.tm_mday,
                              nowTime.tm_hour, nowTime.tm_min, nowTime.tm_sec)
    todayStr = today.strftime("%Y%m%d")

    if (options.debug == True):
        print >>sys.stderr, "Current time: ", today
        print >>sys.stderr, "todayStr: ", todayStr

    # compute day string for yesterday

    oneDay = timedelta(1)
    yesterday = today - oneDay
    yesterdayStr = yesterday.strftime("%Y%m%d")
    if (options.debug == True):
        print >>sys.stderr, "Prev time: ", yesterday
        print >>sys.stderr, "yesterdayStr: ", yesterdayStr

    # perform the archival, to each drive

    for drive in driveList:
        print "drive, device, label: ", \
              drive, deviceTable[drive], labelTable[drive]
        # do yesterday if early in day
        if (nowTime.tm_hour < 2):
            doArchive(drive, labelTable[drive], yesterdayStr)
        # do today
        doArchive(drive, labelTable[drive], todayStr)

    sys.exit(0)

########################################################################
# Get the list of drives

def compileDriveList():

    global driveList
    global deviceTable
    global labelTable

    deviceTable = {}
    labelTable = {}

    # run df to get drive stats
    
    pipe = subprocess.Popen('df', shell=True,
                            stdout=subprocess.PIPE).stdout
    lines = pipe.readlines()

    # load up drive list and associated tables
    
    driveList = []
    for line in lines:
        tokens = line.split()
        if (tokens[0].find('/dev') >= 0):
            partition = tokens[5]
            if (partition.find('SPOL') >= 0):
                driveList.append(partition)
                deviceName = tokens[0]
                deviceTable[partition] = deviceName

    # sort drive list
    
    driveList.sort()

    # run e2label to get volume label
    
    for drive in driveList:
        deviceName = deviceTable[drive]
        e2labelCmd = 'e2label ' + deviceName
        pipe = subprocess.Popen(e2labelCmd, shell=True,
                                stdout=subprocess.PIPE).stdout
        tokens = pipe.readlines()
        if (len(tokens) == 0):
            labelTable[drive] = "unknown"
            print >>sys.stderr, "ERROR: compileDriveList()"
            print >>sys.stderr, "  Cannot run e2label"
        else:
            driveLabel = tokens[0].rstrip()
            labelTable[drive] = driveLabel

########################################################################
# Do the archive

def doArchive(drive, volLabel, dayStr):

    # compute target dir

    targetDir = drive;
    targetDir = os.path.join(targetDir, "field_data")
    targetDir = os.path.join(targetDir, options.projectName)
    
    # compute base command

    baseCmd = "doDayArchive.py"
    if (options.debug == True):
        baseCmd = baseCmd + ' --debug'
    baseCmd = baseCmd + " --source " + options.sourceDir
    baseCmd = baseCmd + " --target " + targetDir
    baseCmd = baseCmd + " --volLabel " + volLabel
    baseCmd = baseCmd + " --dayStr " + dayStr

    # archive for primary list
    
    cmd = baseCmd + " --dirListPath " + options.primaryListPath
    runCommand(cmd)

    # archive for secondary list
    
    cmd = baseCmd + " --dirListPath " + options.secondaryListPath
    cmd = cmd + " --secondary"
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
