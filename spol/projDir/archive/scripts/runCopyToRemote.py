#!/usr/bin/env python

# ========================================================================== #
#
# Copy the archive data to SPOL-DM and SPOL-DM2
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
        print >>sys.stderr, "  Primary dir list path: ", options.primaryListPath
        print >>sys.stderr, "  Secondary dir list path: ", options.secondaryListPath

    # set the list of target hosts

    thisHost = os.getenv("HOSTNAME")
    if (thisHost.find('pgen2') >= 0):
        hostList = [ "spol-dm" ]
    elif (thisHost.find('pgen1') >= 0):
        hostList = [ "spol-dm2" ]
    else:
        print "ERROR - not on a pgen host"
        sys.exit(1)
    
    if (options.debug == True):
        for host in hostList:
            print >>sys.stderr, "target host: ", host
            
    # compute day string for today
    # in test mode we set the daystr directly

    if (options.testMode == True):
        nowTime = time.strptime("20110925010000", "%Y%m%d%H%M%S")
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

    for host in hostList:
        # do yesterday if early in day
        if (nowTime.tm_hour < 3):
            doArchive(host, yesterdayStr)
        # do today
        doArchive(host, todayStr)

    sys.exit(0)

########################################################################
# Do the archive

def doArchive(host, dayStr):

    print "Sending to host: ", host

    # compute base command

    baseCmd = "doCopyToRemote.py"
    if (options.debug == True):
        baseCmd = baseCmd + ' --debug'
    baseCmd = baseCmd + " --remoteHost " + host
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
