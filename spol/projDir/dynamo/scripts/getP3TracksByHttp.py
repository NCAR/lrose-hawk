#!/usr/bin/env python

#===========================================================================
#
# Download P3 tracks from web site using http
#
#===========================================================================

import os
import sys
import time
import datetime
from datetime import timedelta
import string
import subprocess
from optparse import OptionParser
import httplib
import base64

def main():

    global options

    # parse the command line

    parseArgs()

    # initialize
    
    beginString = "BEGIN: getP3TracksByHttp.py"
    today = datetime.datetime.now()
    beginString += " at " + str(today)
    
    print "==========================================================="
    print beginString
    print "==========================================================="

    # create tmp dir if necessary

    if not os.path.exists(options.tmpDir):
        runCommand("mkdir -p " + options.tmpDir)

    # get current time

    nowTime = time.gmtime()
    now = datetime.datetime(nowTime.tm_year, nowTime.tm_mon, nowTime.tm_mday,
                            nowTime.tm_hour, nowTime.tm_min, nowTime.tm_sec)
    nowTimeStr = now.strftime("%Y%m%d%H%M%S")
    dayStr = now.strftime("%Y%m%d")
    remoteDayDir = dayStr + "I1"
    remoteDayDirPath = os.path.join(options.sourceDir, remoteDayDir)
    fileName = dayStr + "I1_iwg1.txt"
    remoteFilePath = os.path.join(remoteDayDirPath, fileName)

    if (options.debug == True):
        print "nowTimeStr: ", nowTimeStr
        print "dayStr: ", dayStr
        print "remoteDayDir: ", remoteDayDir
        print "remoteDayDirPath: ", remoteDayDirPath
        print "fileName: ", fileName
        print "remoteFilePath: ", remoteFilePath

    # open http connection
    
    conn = httplib.HTTPConnection(options.httpServer)
    
    # find the file

    conn.request("GET", remoteFilePath)
    response = conn.getresponse()
    if (options.debug == True):
        print >>sys.stderr, "====>> response status: ", response.status
        print >>sys.stderr, "====>> response reason: ", response.reason
    if (int(response.status) != 200):
        print >>sys.stderr, "ERROR reading file: ", remoteFilePath
        sys.exit(1)
        
    # store in tmp file
                
    tmpPath = os.path.join(options.tmpDir, fileName)
    if (options.verbose == True):
        print >>sys.stderr, "retrieving file, storing as tmpPath: ", tmpPath
        tmpFile = open(tmpPath, 'w')
        tmpFile.write(response.read())
        tmpFile.close()

    # move into place

    targetDayDir = os.path.join(options.targetDir, dayStr)
    if (options.verbose == True):
        print >>sys.stderr, "targetDayDir: ", targetDayDir
        
    # create target day dir if necessary
        
    if not os.path.exists(targetDayDir):
        runCommand("mkdir -p " + targetDayDir)
        
    # move to final location

    cmd = "/bin/mv -f " + tmpPath + " " + targetDayDir
    runCommand(cmd)
    finalPath = os.path.join(targetDayDir, fileName)
    print >>sys.stderr, "File renamed to final path: ", finalPath
    
    # write latest_data_info
    
    relPath = os.path.join(dayStr, fileName)
    cmd = "LdataWriter -dir " + options.targetDir \
          + " -rpath " + relPath \
          + " -writer getP3TracksByHttp.py" \
          + " -dtype txt"
    runCommand(cmd)

    print "=========================================================================="
    print "END: getP3TracksByHttp.py at " + str(datetime.datetime.now())
    print "=========================================================================="

    sys.exit(0)


########################################################################
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
                      help='Set verbose debugging on')
    parser.add_option('--httpServer',
                      dest='httpServer',
                      default='flightscience.noaa.gov',
                      help='Name of http server host')
    parser.add_option('--sourceDir',
                      dest='sourceDir',
                      default='/pub/flight/aamps_ingest/iwg1',
                      help='Path of source directory')
    defaultTargetDir = os.getenv("DATA_DIR") + "/raw/ac_posn/p3"
    parser.add_option('--targetDir',
                      dest='targetDir',
                      default=defaultTargetDir,
                      help='Path of target directory')
    parser.add_option('--tmpDir',
                      dest='tmpDir',
                      default="/tmp/data/raw/ac_posn/p3",
                      help='Path of tmp directory')
    (options, args) = parser.parse_args()

    if (options.verbose == True):
        options.debug = True

    if (options.debug == True):
        print >>sys.stderr, "Options:"
        print >>sys.stderr, "  debug? ", options.debug
        print >>sys.stderr, "  httpServer: ", options.httpServer
        print >>sys.stderr, "  sourceDir: ", options.sourceDir
        print >>sys.stderr, "  tmpDir: ", options.tmpDir

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
# Check file name against list of substrings

def checkFileName(fileName):

    if (options.checkNames == False):
        return True

    subStrList = string.split(options.subStrList, ',')
    found = False

    for subStr in subStrList:

        if (fileName.find(subStr) >= 0):
            if (options.verbose == True):
                print "  -->> subStr '" + subStr + "' matches"
                print "       fileName: ", fileName
            return True

    # substring match not found
    # don't process this file

    if (options.verbose == True):
        print "  -->> fileName does not match subStrings: ", fileName
        print "       subStringList: '", options.subStrList, "'"

    return False

########################################################################
# kick off main method

if __name__ == "__main__":

   main()
