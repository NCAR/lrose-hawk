#!/usr/bin/env python

#===========================================================================
#
# Translate FALCON tracks from archive back into realtime format
#
#===========================================================================

import os
import sys
import subprocess
from optparse import OptionParser

def main():

    global options
    global debug
    global lineList

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
    parser.add_option('--file',
                      dest='inputFilePath',
                      default='/tmp/fs110042_meghatropiques_edited.txt',
                      help='Input file path')
    parser.add_option('--callSign',
                      dest='callSign',
                      default='FGBTM',
                      help='aircraft call sign')
    parser.add_option('--year',
                      dest='year',
                      default=2011,
                      help='Set the year')
    parser.add_option('--month',
                      dest='month',
                      default=11,
                      help='Set the month')
    parser.add_option('--day',
                      dest='day',
                      default=1,
                      help='Set the day')
    
    (options, args) = parser.parse_args()

    if (options.verbose == True):
        options.debug = True

    if (options.debug == True):
        print >>sys.stderr, "Running doDayArchive:"
        print >>sys.stderr, "  inputFilePath: ", options.inputFilePath

    # read in file

    readInputFile()

    if (options.verbose == True):
        print >>sys.stderr, "======================="
        print >>sys.stderr, "Line list:"
        for line in lineList:
            print >>sys.stderr, "  -->> ", line
        print >>sys.stderr, "======================="

    # decode lines, print reformatted to stdout

    for line in lineList:
        tokens = line.split()
        if (len(tokens) < 4): continue
        secsInDay = int(float(tokens[0]) + 0.5)
        hour = secsInDay / 3600
        min = (secsInDay - hour * 3600) / 60
        sec = secsInDay - hour * 3600 - min * 60
        altitudeMeters = float(tokens[1])
        latitudeDeg = float(tokens[2])
        longitudeDeg = float(tokens[3])
        print "%s,%.4d%.2d%.2dT%.2d%.2d%.2d,%.6f,%.6f,%.2f" % \
              (options.callSign,
               int(options.year), int(options.month), int(options.day),
               hour, min, sec,
               latitudeDeg, longitudeDeg, altitudeMeters)
        
    sys.exit(0)

########################################################################
# Read in the input file

def readInputFile():

    global lineList

    fp = open(options.inputFilePath, 'r')
    lines = fp.readlines()
    lineList = []
    for line in lines:
        if (line[0] != '#' and len(line) > 1):
            lineList.append(line.strip())

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
