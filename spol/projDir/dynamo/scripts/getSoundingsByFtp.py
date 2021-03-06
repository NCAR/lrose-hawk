#!/usr/bin/env python

#=====================================================================
#
# Download sounding files from ftp site
#
#=====================================================================

import os
import sys
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
    
    beginString = "BEGIN: getSoundingsByFtp.py"
    today = datetime.datetime.now()
    beginString += " at " + str(today)
    
    if (options.force == True):
        skipFtp = 0
        beginString += " (ftp forced)"

    print "\n========================================================"
    print beginString
    print "========================================================="

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
    fileList = ftp.nlst()

    # go through files in list

    count = 0
    for fileName in fileList:

        if (options.verbose == True):
            print >>sys.stderr, "  fileName: ", fileName

        # get date and time

        dateStr = ""
        dateTimeStr = ""

        if (fileName.find(".D20") > 0):
            index = fileName.find(".D20")
            dateStr = fileName[index+2:index+10]
            timeStr = fileName[index+11:index+17]
            dateTimeStr = dateStr + timeStr
        elif ((fileName.find(".cls.") > 0) and (fileName.find("_20") > 0)):
            index = fileName.find("_20")
            dateStr = fileName[index+1:index+9]
            dateTimeStr = fileName[index+1:index+13] + "00"
        else:
            print >>sys.stderr, "ERROR - getSoundingsByFtp.py"
            print >>sys.stderr, "  Cannot get date and time from file name"
            print >>sys.stderr, "  File: ", fileName
            continue
            
        if (options.verbose == True):
            print >>sys.stderr, "  dateStr: ", dateStr
            print >>sys.stderr, "  dateTimeStr: ", dateTimeStr

        nowTimeVal = int(nowTimeStr)
        startTimeVal = int(startTimeStr)
        fileTimeVal = int(dateTimeStr)

        if (options.verbose == True):
            print >>sys.stderr, "    nowTimeVal: ", nowTimeVal
            print >>sys.stderr, "  startTimeVal: ", startTimeVal
            print >>sys.stderr, "   fileTimeVal: ", fileTimeVal

        # only get files from the past, and after the start time

        doGet = False
        if ((fileTimeVal < nowTimeVal) and (fileTimeVal >= startTimeVal)):
            doGet = True

        if (options.verbose == True):
            if (doGet):
                print >>sys.stderr, "-->> Checking file for time: ", fileTimeVal
            else:
                print >>sys.stderr, "-->> Skipping file for time: ", fileTimeVal
            
        if (doGet):
            dayDir = os.path.join(options.targetDir, dateStr)
            if (options.verbose == True):
                print >>sys.stderr, "dayDir: ", dayDir

            # create day dir if necessary

            if not os.path.exists(dayDir):
                runCommand("mkdir -p " + dayDir)

            # check if file has already been retrieved
            
            fileAlreadyHere = False
            for root, dirs, localfiles in os.walk(dayDir):
                for localName in localfiles:
                    if (localName == fileName):
                        fileAlreadyHere = True

            if (options.verbose == True):
                print >>sys.stderr, "fileAlreadyHere: ", fileAlreadyHere
                            
            if ((fileAlreadyHere == False) or (options.force == True)):

                # get file, store in tmp
                
                tmpPath = os.path.join(options.tmpDir, fileName)
                if (options.verbose == True):
                    print >>sys.stderr, "retrieving file, storing as tmpPath: ", tmpPath
                ftp.retrbinary('RETR '+ fileName, open(tmpPath, 'wb').write)

                # move to final location
                
                cmd = "mv " + tmpPath + " " + dayDir
                runCommand(cmd)
                print >>sys.stderr, "writing file: ", fileName

                # write latest_data_info
                
                relPath = os.path.join(dateStr, fileName)
                cmd = "LdataWriter -dir " + options.targetDir \
                      + " -rpath " + relPath \
                      + " -ltime " + str(fileTimeVal) \
                      + " -writer getSoundingsByFtp.py" \
                      + " -dtype nc"
                runCommand(cmd)

                count += 1

    # close ftp connection
                
    ftp.quit()

    if (count == 0):
        print "---->> No files to download"
        
    print "==============================================================="
    print "END: getSoundingsByFtp.py at " + str(datetime.datetime.now())
    print "==============================================================="

    sys.exit(0)


########################################################################
# Parse the command line

def parseArgs():
    
    global options

    defaultTargetDir = os.getenv("DATA_DIR") + "/raw/soundings"
    defaultTmpDir = "/tmp/data/raw/soundings"

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
                      default='ftp.eol.ucar.edu',
                      help='Name of ftp server host')
    parser.add_option('--sourceDir',
                      dest='sourceDir',
                      default='/pub/archive/iss/dynamo/iss2/class',
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
