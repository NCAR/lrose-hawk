#!/usr/bin/env python

#================================================================
#
# create make link for each file in the dated subdirectories
#
#================================================================

import os
import sys
import time
import datetime
from datetime import timedelta
import string
import subprocess
from optparse import OptionParser

def main():

    global options

    # parse the command line

    parseArgs()

    # go to the directory

    if (os.path.exists(options.dirPath) == False):
        print "WARNING - createSubdirLinks"
        print "  dir does not exist: ", options.dirPath
        print "  ignoring"
        sys.exit(1)

    os.chdir(options.dirPath)
    if (options.debug == True):
        print "working on dir: ", options.dirPath

    linksDir = os.path.join(options.dirPath, "links")

    # mkdir the links subdirectory if it does not exist

    if (os.path.exists(linksDir) == False):
        os.mkdir(linksDir)

    # add in a _Scout file to prevent Scout from 
    # traversing this directory

    scoutPath = os.path.join(linksDir, "_Scout")
    scoutFile = open(scoutPath, 'w')
    scoutFile.write('Recurse = FALSE;\n')
    scoutFile.close()

    # add in a _Janitor file to prevent Janitor from 
    # traversing this directory

    janitorPath = os.path.join(linksDir, "_Janitor")
    janitorFile = open(janitorPath, 'w')
    janitorFile.write('recurse = FALSE;\nprocess = FALSE;\n')
    janitorFile.close()

    # clean the links of any links which no longer
    # point to files

    cleanLinks(linksDir)
    
    # get listing of dated dirs
    
    dirList = os.listdir(options.dirPath)

    for dir in dirList:
        if (dir.find("20") == 0):
            # create the links
            subDirPath = os.path.join(options.dirPath, dir)
            createLinks(subDirPath, linksDir)

    sys.exit(0)

#############################################
# make the links for a particular directory

def createLinks(subDirPath, linksDir):

    # go to the subdir

    if (options.debug == True):
        print "working on subdir: ", subDirPath

    # get a listing

    os.chdir(subDirPath)
    fileList = os.listdir(subDirPath)

    # go to the links dir

    os.chdir(linksDir)

    # create the links

    for fileName in fileList:
        # do not make links to compressed files
        if (fileName.find(".gz") < 0):
            linkName = os.path.join(subDirPath, fileName)
            if (os.path.exists(fileName) == False):
                if (options.debug == True):
                    print "creating link: ", linkName
                os.symlink(linkName, fileName)

    return

#############################################
# clean the links for a particular directory
# by removing links which no longer point to files
# most likely because the file was compressed, 
# or removed

def cleanLinks(linksDir):
    
    os.chdir(linksDir)
    linkList = os.listdir(linksDir)
    for linkName in linkList:
        if (os.path.exists(linkName) == False):
            if (options.debug == True):
                print "deleting old link: ", linkName
            os.unlink(linkName)

    return

######################################################
# Parse the command line

def parseArgs():
    
    global options

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
                      help='Set verbose debuggin on')
    parser.add_option('--dirPath',
                      dest='dirPath',
                      default='/tmp/junk',
                      help='Path to directory')

    (options, args) = parser.parse_args()

    if (options.verbose == True):
        options.debug = True

    if (options.debug == True):
        print >>sys.stderr, "Options:"
        print >>sys.stderr, "  debug? ", options.debug
        print >>sys.stderr, "  dirPath? ", options.dirPath

################################################################
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

###########################################################
# kick off main method

if __name__ == "__main__":

   main()
