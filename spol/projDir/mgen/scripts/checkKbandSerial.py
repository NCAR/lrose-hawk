#!/usr/bin/env python

#===========================================================================
#
# Check Ka-band serial connection
#
# Reset the serial connection if it is down
#
#===========================================================================

import os
import sys
import subprocess
from optparse import OptionParser
import time
import datetime
from datetime import date
from datetime import timedelta

def main():

    global options
    global debug
    global statusLines

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
    parser.add_option('--statusPath',
                      dest='statusPath', default='/tmp/RadMon.log',
                      help='Path to status file')

    (options, args) = parser.parse_args()

    if (options.verbose == True):
        options.debug = True

    now = datetime.datetime.now()

    if (options.debug == True):
        print >>sys.stderr, "Running checkKbandSerial:"
        print >>sys.stderr, "  time: ", now
        print >>sys.stderr, "  statusPath: ", options.statusPath
        
    # read in lines from status file

    readStatusFile()
    
    if (options.verbose == True):
        for line in statusLines:
            print >>sys.stderr, "Got line: ", line

    # we should have found 1 line
    
    if (len(statusLines) < 1):
        print >>sys.stderr, "Running checkKbandSerial:"
        print >>sys.stderr, "  statusPath: ", options.statusPath
        print >>sys.stderr, "  cannot find SerialConnected entry"
        sys.exit(-1)
        
    # is serial line OK?

    for line in statusLines:
        statusStr = line[0:1]
        if (statusStr.isdigit()):
            statusVal = int(statusStr)
            if (options.debug == True):
                print >>sys.stderr, "statusVal: ", statusVal
            if (statusVal == 0):
                print >>sys.stderr, "  GOOD - serial line is OK"
            else:
                print >>sys.stderr, "  WARNING - serial line is down"
                resetSerialLine()
            break

    sys.exit(0)

########################################################################
# Read in the status file

def readStatusFile():

    global statusLines
    statusLines = []
    
    fp = open(options.statusPath, 'r')
    text = fp.read()
    lines = text.splitlines()

    for line in lines:
        if ((line.find("SerialConnected") >= 0)):
            statusLines.append(line)

########################################################################
# Read in the status file

def resetSerialLine():

    if (options.debug == True):
        print >>sys.stderr, "Resetting the serial line"

    cmd = "ssh kadrx reset_kadrx_serial"
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
