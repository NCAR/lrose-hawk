#!/usr/bin/env python

# ========================================================================== #
#
# Scrub archive disks, keeping them below 90%
#
# This should be run only on the secondary archive host (normally spol-dm2)
# since the primary host should never be scrubbed.
#
# ========================================================================== #

import os
import sys
import subprocess
import time
import datetime
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
    
    print >>sys.stderr, "====================================================="
    print >>sys.stderr, "START: scrubArchiveDisks at " + str(datetime.datetime.now())
    print >>sys.stderr, "====================================================="

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
    parser.add_option('--minSpace',
                      dest='minSpace', default='150',
                      help='Warn at this level (GBytes)')
    
    (options, args) = parser.parse_args()

    if (options.verbose == True):
        options.debug = True

    if (options.debug == True):
        print >>sys.stderr, "Options:"
        print >>sys.stderr, "  Debug: ", options.debug
        print >>sys.stderr, "  minSpace (GBytes): ", options.minSpace
        
    # compile the list of archive drives, including their sizes
    # and available space

    compileDriveList()

    if (len(driveList) == 0):
        print >>sys.stderr, "ERROR - scrubArchiveDisks.py"
        print >>sys.stderr, "  No drives found"
        sys.exit(1)

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
            if (int(availGBytes) < int(options.minSpace)):
                print >>sys.stderr, "  WARNING, less than min allowed: ", options.minSpace
            else:
                print >>sys.stderr, "  OK - available space > min allowed: ", options.minSpace
                print >>sys.stderr, "       nothing to do"

    # XXXXXXXXX exit now - disable script XXXXXXXXXXX

    print >>sys.stderr, "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
    print >>sys.stderr, "XXXXXX exiting now - script disabled XXXXXXX"
    print >>sys.stderr, "XXXXXX edit script to re-enble       XXXXXXX"
    print >>sys.stderr, "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
    sys.exit(0)
        
    # check if we need to scrub

    for drive in driveList:

        label = labelTable[drive]
        usedGBytes = spaceUsedTable[drive]
        availGBytes = spaceAvailTable[drive]
        totalGBytes = spaceTotalTable[drive]
        if (int(availGBytes) < int(options.minSpace)):
            scrubEarliestDay(drive)

    print >>sys.stderr, "====================================================="
    print >>sys.stderr, "END: scrubArchiveDisks at " + str(datetime.datetime.now())
    print >>sys.stderr, "====================================================="

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
# Scrub the earliest day from the disk

def scrubEarliestDay(drive):

    global earliestDate
    global dirsToScrub
    
    earliestDate = 99999999
    dirsToScrub = []
    
    if (options.debug == True):
        print >>sys.stderr, "Scrubbing drive: ", drive

    topDir = os.path.join(drive, "field_data/dynamo")

    if (options.debug == True):
        print >>sys.stderr, "  topDir: ", topDir

    level = 0
    findEarliestDay(topDir, level)
        
    print >>sys.stderr, "  earliestDate found on drive: ", earliestDate

    # find the directories to scrub
    
    findDirsToScrub(topDir, level)

    for dir in dirsToScrub:
        scrubDir(dir, 0)

########################################################################
# Recursively find earlist day

def findEarliestDay(dir, level):

    global earliestDate
    
    if (options.verbose == True):
        print >>sys.stderr, "findEarliestDay: dir, level: ", dir, ", ", level
    
    if (level > 20):
        # too deep
        print >>sys.stderr, "ERROR - recursion too deep"
        return

    contents = os.listdir(dir)
    for entry in contents:
        subDir = os.path.join(dir, entry)
        if (os.path.isdir(subDir)):

            # check for dated dir
            if (len(entry) == 8 and str.isdigit(entry)):
                year = int(entry[:4])
                month = int(entry[4:6])
                day = int(entry[6:8])
                if (year >= 2000 and year <= 2100 and \
                    month >= 1 and month <= 12 and \
                    day >= 1 and day <= 31):
                    dateInt = year * 10000 + month * 100 + day
                    if (dateInt < earliestDate):
                        earliestDate = dateInt
                        if (options.debug == True):
                            print >>sys.stderr, "  ===>> earliestDate so far: ", earliestDate

            # recurse
            findEarliestDay(subDir, level + 1)

    return

########################################################################
# find dirs for scrubbing

def findDirsToScrub(dir, level):

    global dirsToScrub

    if (options.verbose == True):
        print >>sys.stderr, "findDirsToScrub: dir, level: ", dir, ", ", level
    
    if (level > 20):
        # too deep
        print >>sys.stderr, "ERROR - recursion too deep"
        return

    contents = os.listdir(dir)
    for entry in contents:
        subDir = os.path.join(dir, entry)
        if (os.path.isdir(subDir)):
            
            if (options.verbose == True):
                print >>sys.stderr, "  ===>> checking dir: ", subDir
            # check for dated dir
            if (len(entry) == 8 and str.isdigit(entry)):
                year = int(entry[:4])
                month = int(entry[4:6])
                day = int(entry[6:8])
                if (year >= 2000 and year <= 2100 and \
                    month >= 1 and month <= 12 and \
                    day >= 1 and day <= 31):
                    dateInt = year * 10000 + month * 100 + day
                    if (dateInt == earliestDate):
                        # this dir matches the earliest date
                        dirsToScrub.append(subDir)
                        if (options.verbose == True):
                            print >>sys.stderr, "  ===>> scrub dir: ", subDir
                        return
                        
            # recurse
            findDirsToScrub(subDir, level + 1)

    return

########################################################################
# scrub this dir

def scrubDir(dir, level):

    print >>sys.stderr, "===>> Scrubbing dir: ", dir, ", level: ", level
    if (level > 20):
        print >>sys.stderr, "======>> recursion too deep, stopping here"
        return
    
    contents = os.listdir(dir)
    for entry in contents:
        path = os.path.join(dir, entry)
        if (os.path.isdir(path)):
            scrubDir(path, level + 1)
        else:
            if (options.verbose):
                print >>sys.stderr, "Removing file: ", path
            os.unlink(path)
            
    if (options.verbose):
        print >>sys.stderr, "Removing dir: ", dir
    os.rmdir(dir)
        
    return

########################################################################
# Run - entry point

if __name__ == "__main__":
   main()
