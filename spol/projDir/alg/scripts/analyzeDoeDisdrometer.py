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

from netCDF4 import Dataset
from netCDF4 import MFDataset

def main():
    
    global options
    global scriptName
    scriptName = "analyzeDoeDisdrometer"
    
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
                      dest='filePath', default='/tmp/params',
                      help='Path of input file')

    (options, args) = parser.parse_args()
    
    if (options.verbose == True):
        options.debug = True
        
    # print out running state
    
    if (options.debug == True):
        print >>sys.stderr, "Running %s:" % scriptName
        print >>sys.stderr, "  file: ", options.filePath

    # read in and process file

    processFile(options.filePath)

    sys.exit(0)

########################################################################
# Read in the directory list

def processFile(filePath):

    ds = Dataset(filePath)

    if (options.verbose == True):
        print ds.variables['rain_rate'][:]
        print ds

    maxRate = max(ds.variables['rain_rate'][:])
    print "Path: ", filePath
    print "  max rate: ", maxRate


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
