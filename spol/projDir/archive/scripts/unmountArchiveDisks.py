#!/usr/bin/env python

# ========================================================================== #
#
# Unmount the archive disks
#
# ========================================================================== #

import os
import sys
import subprocess
from optparse import OptionParser

def main():

    global options
    global debug
    global driveList
    global deviceTable
    global labelTable
    global spaceUsedTable
    global spaceAvailTable
    global spaceTotalTable

    # parse the command line

    usage = "usage: %prog [options]"
    parser = OptionParser(usage)
    parser.add_option('--debug',
                      dest='debug', default='False',
                      action="store_true",
                      help='Set debugging on')

    (options, args) = parser.parse_args()

    if (options.debug == True):
        print >>sys.stderr, "Options:"
        print >>sys.stderr, "  Debug: ", options.debug

    # compile the list of target drives

    compileDriveList()

    if (options.debug == True):
        print >>sys.stderr, "  archive drive list: ", driveList

    # unmount the drives

    for drive in driveList:
        unmountDrive(drive)

    sys.exit(0)

########################################################################
# Get the list of drives and available space

def compileDriveList():

    global driveList
    global deviceTable
    global labelTable
    global spaceUsedTable
    global spaceAvailTable
    global spaceTotalTable

    deviceTable = {}
    labelTable = {}
    spaceUsedTable = {}
    spaceAvailTable = {}
    spaceTotalTable = {}

    # run df
    
    pipe = subprocess.Popen('df --block-size=1G', shell=True,
                            stdout=subprocess.PIPE).stdout
    lines = pipe.readlines()
    
    # load up drive list and associated tables
    
    driveList = []
    for line in lines:
        tokens = line.split()
        if (tokens[0].find('/dev') >= 0):
            partition = tokens[5]
            if (partition.find('SPOL_') >= 0):
                driveList.append(partition)
                deviceName = tokens[0]
                totalGBytes = tokens[1]
                usedGBytes = tokens[2]
                availGBytes = tokens[3]
                deviceTable[partition] = deviceName
                spaceUsedTable[partition] = usedGBytes
                spaceAvailTable[partition] = availGBytes
                spaceTotalTable[partition] = totalGBytes

    # sort drive list
    
    driveList.sort()

    # run e2label to get volume label
    
    for drive in driveList:
        deviceName = deviceTable[drive]
        e2labelCmd = 'e2label ' + deviceName
        pipe = subprocess.Popen(e2labelCmd, shell=True,
                                stdout=subprocess.PIPE).stdout
        tokens = pipe.readlines()
        driveLabel = tokens[0].rstrip()
        labelTable[drive] = driveLabel

########################################################################
# Unmount the drive

def unmountDrive(drive):

    cmd = 'umount ' + drive
    print "--->> unmountArchiveDisks, running cmd: ", cmd
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
