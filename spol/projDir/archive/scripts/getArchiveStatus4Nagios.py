#!/usr/bin/env python

# ========================================================================== #
#
# Get archive status, write nagios string
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
    parser.add_option('--warnSpace',
                      dest='warnSpace', default='250',
                      help='Warn at this level (GBytes)')
    parser.add_option('--critSpace',
                      dest='critSpace', default='200',
                      help='Critical at this level (GBytes)')
    
    (options, args) = parser.parse_args()

    if (options.debug == True):
        print >>sys.stderr, "Options:"
        print >>sys.stderr, "  Debug: ", options.debug
        print >>sys.stderr, "  warnSpace (GBytes): ", options.warnSpace
        print >>sys.stderr, "  critSpace (GBytes): ", options.critSpace
        
    # compile the list of archive drives, including their sizes
    # and available space

    compileDriveList()

    # debug print to stderr
    
    if (options.debug == True):
        for drive in driveList:
            label = labelTable[drive]
            usedGBytes = spaceUsedTable[drive]
            availGBytes = spaceAvailTable[drive]
            print >>sys.stderr, "Drive: ", drive
            print >>sys.stderr, "  label: ", label
            print >>sys.stderr, "  used(GBytes): ", usedGBytes
            print >>sys.stderr, "  avail(GBytes): ", availGBytes
            if (availGBytes < options.critSpace):
                print >>sys.stderr, "  CRITICAL, less than: ", options.critSpace
            elif (availGBytes < options.warnSpace):
                print >>sys.stderr, "  WARNING, less than: ", options.warnSpace
        
    # write the nagios output to stdout

    for drive in driveList:
        label = labelTable[drive]
        usedGBytes = spaceUsedTable[drive]
        availGBytes = spaceAvailTable[drive]
        totalGBytes = spaceTotalTable[drive]
        spolStr = drive.find('SPOL')
        driveStr = drive[spolStr:]
        nagiosLabel = "USB_Archive_" + driveStr
        status = 0
        statusStr = "OK"
        if (int(availGBytes) < int(options.critSpace)):
            status = 2
            statusStr = "CRIT"
        elif (int(availGBytes) < int(options.warnSpace)):
            status = 1
            statusStr = "WARN"

        percentAvail = (float(availGBytes) / float(totalGBytes)) * 100.0

        print "%d %s availGBytes=%s;%s;%s;0;%s; %s - drive %s, avail %.1f%%" % \
              (status, nagiosLabel, \
               availGBytes, options.warnSpace, options.critSpace, totalGBytes, \
               statusStr, label, percentAvail)

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
        if (len(tokens) > 1):
            driveLabel = tokens[0].rstrip()
        else:
            driveLabel = "Unknown"
        labelTable[drive] = driveLabel

########################################################################
# Run - entry point

if __name__ == "__main__":
   main()
