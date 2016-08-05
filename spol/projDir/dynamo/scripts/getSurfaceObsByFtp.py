#!/usr/bin/env python

#=====================================================================
#
# Download surface obes files from ftp site
#
#=====================================================================

import os
import sys
from stat import *
import time
import datetime
from datetime import timedelta
import string
import ftplib
import subprocess
from optparse import OptionParser

def main():

    global options
    global ftpUser
    global ftpPassword
    global ftpDebugLevel
    global skipFtp
    global tmpDir

    ftpUser = "anonymous"
    ftpPassword = ""
    skipFtp = 0

    # parse the command line

    parseArgs()

    # initialize
    
    beginString = "BEGIN: getSurfaceObsByFtp.py"
    today = datetime.datetime.now()
    beginString += " at " + str(today)
    
    if (options.force == True):
        skipFtp = 0
        beginString += " (ftp forced)"

    print "\n============================================================"
    print beginString
    print "=============================================================="

    if (skipFtp):
        print "skipping FTP of", options.sourceDir, " to", options.targetDir
        sys.exit(0)

    # create tmp dir if necessary

    if not os.path.exists(options.tmpDir):
        runCommand("mkdir -p " + options.tmpDir)

    # set ftp debug level

    if (options.verbose == True):
        ftpDebugLevel = 2
    elif (options.debug == True):
        ftpDebugLevel = 1
    else:
        ftpDebugLevel = 0
    
    print "FTP: debugLevel, server, user, sourceDir, targetDir:"
    print " ", ftpDebugLevel, options.ftpServer, ftpUser,\
          options.sourceDir, options.targetDir

    # open ftp connection
    
    ftp = ftplib.FTP(options.ftpServer, ftpUser, ftpPassword)
    ftp.set_debuglevel(ftpDebugLevel)
    
    # get current time

    nowTime = time.gmtime()
    now = datetime.datetime(nowTime.tm_year, nowTime.tm_mon, nowTime.tm_mday,
                            nowTime.tm_hour, nowTime.tm_min, nowTime.tm_sec)
    nowTimeStr = now.strftime("%Y%m%d%H%M%S")

    # compute start time

    pastSecs = timedelta(0, int(options.pastSecs))
    startTime = now - pastSecs
    startTimeStr = startTime.strftime("%Y%m%d%H%M%S")

    if (options.debug == True):
        print >>sys.stderr, "  time now: ", nowTimeStr
        print >>sys.stderr, "  getting data after: ", startTimeStr

    # get file list from server
    
    ftp.cwd(options.sourceDir)
    dirLines = []
    ftp.dir(dirLines.append)
   
    # go through files in list

    count = 0
    for dirEntry in dirLines:
        
        fileDetails = dirEntry.split()
        fileName = fileDetails[8]
        remoteSize = fileDetails[4]

        if (options.verbose == True):
            print "  fileName: ", fileName
            print "  remoteSize: ", remoteSize

        parts = string.split(fileName, '.')
        dateStr = parts[0][:8]
        dateTimeStr = parts[0][:10]
        if (options.verbose == True):
            print "  dateStr: ", dateStr
            print "  dateTimeStr: ", dateTimeStr

        nowTimeVal = int(nowTimeStr)
        startTimeVal = int(startTimeStr)
        fileTimeVal = int(dateTimeStr) * 10000

        if (options.verbose == True):
            print "    nowTimeVal: ", nowTimeVal
            print "  startTimeVal: ", startTimeVal
            print "   fileTimeVal: ", fileTimeVal

        # only get files from the past, and after the start time

        doGet = False
        if ((fileTimeVal < nowTimeVal) and (fileTimeVal >= startTimeVal)):
            doGet = True

        if (options.verbose == True):
            if (doGet):
                print "-->> Checking file for time: ", fileTimeVal
            else:
                print "-->> Skipping file for time: ", fileTimeVal
            
        if (doGet):
            dayDir = os.path.join(options.targetDir, dateStr)
            localPath = os.path.join(dayDir, fileName)
            if (options.verbose == True):
                print "dayDir: ", dayDir
                print "localPath: ", localPath

            # create day dir if necessary

            if not os.path.exists(dayDir):
                runCommand("mkdir -p " + dayDir)

            # check if file has already been retrieved and is the same
            # size as on the remote side

            fileAlreadyHere = False
            if (os.path.exists(localPath)):
                fileStats = os.stat(localPath)
                localSize = fileStats[ST_SIZE]
                if (options.verbose == True):
                    print "  -->> remoteSize: ", remoteSize
                    print "  -->> localSize: ", localSize
                if (int(localSize) == int(remoteSize)):
                    fileAlreadyHere = True
            
            if (options.verbose == True):
                print "fileAlreadyHere: ", fileAlreadyHere
                
            if ((fileAlreadyHere == False) or (options.force == True)):

                # get file, store in tmp
                
                tmpPath = os.path.join(options.tmpDir, fileName)
                if (options.verbose == True):
                    print "retrieving file, storing as tmpPath: ", tmpPath
                ftp.retrbinary('RETR '+ fileName, open(tmpPath, 'wb').write)

                # move to final location
                
                cmd = "mv " + tmpPath + " " + dayDir
                runCommand(cmd)
                print "writing file: ", fileName

                # write latest_data_info
                
                relPath = os.path.join(dateStr, fileName)
                cmd = "LdataWriter -dir " + options.targetDir \
                      + " -rpath " + relPath \
                      + " -ltime " + str(fileTimeVal) \
                      + " -writer getSurfaceObsByFtp.py" \
                      + " -dtype txt"
                runCommand(cmd)

                count += 1

    # close ftp connection
                
    ftp.quit()

    if (count == 0):
        print "---->> No files to download"
        
    print "=========================================================================="
    print "END: getSurfaceObsByFtp.py at " + str(datetime.datetime.now())
    print "=========================================================================="

    sys.exit(0)


########################################################################
# Parse the command line

def parseArgs():
    
    global options

    defaultTargetDir = os.getenv("DATA_DIR") + "/raw/surface_obs"
    defaultTmpDir = "/tmp/data/raw/surface_obs"

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
    parser.add_option('--force',
                      dest='force', default='False',
                      action="store_true",
                      help='Force ftp transfer')
    parser.add_option('--ftpServer',
                      dest='ftpServer',
                      default='catalog1.eol.ucar.edu',
                      help='Name of ftp server host')
    parser.add_option('--sourceDir',
                      dest='sourceDir',
                      default='/pub/incoming/dynamo/met',
                      help='Path of source directory')
    parser.add_option('--targetDir',
                      dest='targetDir',
                      default=defaultTargetDir,
                      help='Path of target directory')
    parser.add_option('--tmpDir',
                      dest='tmpDir',
                      default=defaultTmpDir,
                      help='Path of tmp directory')
    parser.add_option('--pastSecs',
                      dest='pastSecs',
                      default=7200,
                      help='How far back to retrieve (secs)')

    (options, args) = parser.parse_args()

    if (options.verbose == True):
        options.debug = True

    if (options.debug == True):
        print >>sys.stderr, "Options:"
        print >>sys.stderr, "  debug? ", options.debug
        print >>sys.stderr, "  force? ", options.force
        print >>sys.stderr, "  ftpServer: ", options.ftpServer
        print >>sys.stderr, "  sourceDir: ", options.sourceDir
        print >>sys.stderr, "  tmpDir: ", options.tmpDir
        print >>sys.stderr, "  pastSecs: ", options.pastSecs

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
# kick off main method

if __name__ == "__main__":

   main()
