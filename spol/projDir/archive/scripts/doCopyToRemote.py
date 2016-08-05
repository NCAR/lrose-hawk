#!/usr/bin/env python

#===========================================================================
#
# Do copy archive data to remote host
#
#===========================================================================

import os
import sys
import subprocess
from optparse import OptionParser

def main():

    global options
    global debug
    global dirList

    # parse the command line

    usage = "usage: %prog [options]"
    homeDir = os.environ['HOME']
    dataDir = os.path.join(homeDir, 'projDir/data')
    parser = OptionParser(usage)
    parser.add_option('--debug',
                      dest='debug', default='False',
                      action="store_true",
                      help='Set debugging on')
    parser.add_option('--source',
                      dest='sourceDir', default=dataDir,
                      help='Path of source directory on local host')
    parser.add_option('--target',
                      dest='targetDir', default='projDir/data',
                      help='Path of target directory on remote host')
    parser.add_option('--remoteHost',
                      dest='remoteHost', default='spol-dm',
                      help='Name of remote host')
    parser.add_option('--dayStr',
                      dest='dayStr', default='20110901',
                      help='String for day, format dir: yyyymmdd')
    parser.add_option('--dirListPath',
                      dest='dirListPath',
                      default='/tmp/dirListPath',
                      help='Path to file containing directory list')
    parser.add_option('--secondary',
                      dest='secondary', default='False',
                      action="store_true",
                      help='Using secondary file list')

    (options, args) = parser.parse_args()

    if (options.debug == True):
        print >>sys.stderr, "Running copyToRemote:"
        print >>sys.stderr, "  Source dir: ", options.sourceDir
        print >>sys.stderr, "  Remote host: ", options.remoteHost
        print >>sys.stderr, "  Target dir: ", options.targetDir
        print >>sys.stderr, "  Day string: ", options.dayStr
        print >>sys.stderr, "  Dir list path: ", options.dirListPath
        print >>sys.stderr, "  Secondary? ", options.secondary

    # read in directory list

    readDirList()

    if (options.debug == True):
        print >>sys.stderr, "======================="
        print >>sys.stderr, "Dir list:"
        for dir in dirList:
            print >>sys.stderr, "  -->> ", dir
        print >>sys.stderr, "======================="

    # do the rsync

    if (options.secondary == True):
        for dir in dirList:
            doRsyncSecondary(dir)
    else:
        for dir in dirList:
            doRsyncPrimary(dir)

    sys.exit(0)

########################################################################
# Read in the directory list

def readDirList():

    global dirList

    fp = open(options.dirListPath, 'r')
    lines = fp.readlines()
    dirList = []
    for line in lines:
        if (line[0] != '#' and len(line) > 1):
            dirList.append(line.strip())


########################################################################
# perform rsync on directory list - primary
# these files are in dated sub-directories

def doRsyncPrimary(dir):

    sourceDir = os.path.join(options.sourceDir, dir)
    sourceDayDir = os.path.join(sourceDir, options.dayStr)
    targetDir = os.path.join(options.targetDir, dir)
    targetLoc = options.remoteHost + ":" + targetDir
    
    # rsync day dir if it exists
    
    if (os.path.isdir(sourceDayDir)):

        cmd = "rsync -av --size-only --modify-window 86400 " + sourceDayDir + " " + targetLoc
        if (options.debug == True):
            print >>sys.stderr, "running cmd: ", cmd
        runCommand(cmd)

    else:
        if (options.debug == True):
            print >>sys.stderr, "Dir does not exist: ", sourceDayDir
            

########################################################################
# perform rsync on directory list - secondary
# these files in the source directories

def doRsyncSecondary(dir):

    sourceDir = os.path.join(options.sourceDir, dir)
    targetDir = os.path.join(options.targetDir, dir)
    targetLoc = options.remoteHost + ":" + targetDir
    
    # rsync dir if it exists
    
    if (os.path.isdir(sourceDir)):

        cmd = "rsync -av --size-only --modify-window 86400 " + sourceDir + "/* " + targetLoc
        if (options.debug == True):
            print >>sys.stderr, "running cmd: ", cmd
        runCommand(cmd)

    else:
        if (options.debug == True):
            print >>sys.stderr, "Dir does not exist: ", sourceDir
            

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
