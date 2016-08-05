#!/usr/bin/env python

#===========================================================================
#
# Download sat files from ftp site
#
#===========================================================================

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
    
    beginString = "BEGIN: getSatFilesByFtp.py"
    today = datetime.datetime.now()
    beginString += " at " + str(today)
    
    if (options.force == True):
        skipFtp = 0
        beginString += " (ftp forced)"

    print "==========================================================="
    print beginString
    print "==========================================================="

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
    print " ", ftpDebugLevel, options.ftpServer, ftpUser, options.sourceDir, options.targetDir

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
    for remoteName in fileList:
        
        if (options.verbose == True):
            print "  remoteName: ", remoteName

        # check name against substring list if needed
        
        if (checkFileName(remoteName) == False):
            continue

        # process this file
            
        parts = string.split(remoteName, '.')
        dateStr = parts[1][:8]
        dateTimeStr = parts[1][:12]
        if (options.verbose == True):
            print "  dateStr: ", dateStr
            print "  dateTimeStr: ", dateTimeStr

        startTimeVal = int(startTimeStr)
        fileTimeVal = int(dateTimeStr) * 100

        if (options.verbose == True):
            print "  startTimeVal: ", startTimeVal
            print "   fileTimeVal: ", fileTimeVal

        if (fileTimeVal >= startTimeVal):
        
            dayDir = os.path.join(options.targetDir, dateStr)
            if (options.verbose == True):
                print "dayDir: ", dayDir

            # create day dir if necessary

            if not os.path.exists(dayDir):
                runCommand("mkdir -p " + dayDir)

            # check if file has already been retrieved
            
            fileAlreadyHere = False
            for root, dirs, localfiles in os.walk(dayDir):
                for localName in localfiles:
                    if (localName == remoteName):
                        fileAlreadyHere = True

            if (options.verbose == True):
                print "fileAlreadyHere: ", fileAlreadyHere
                            
            if ((fileAlreadyHere == False) or (options.force == True)):

                # get file, store in tmp
                
                tmpPath = os.path.join(options.tmpDir, remoteName)
                if (options.verbose == True):
                    print "retrieving file, storing as tmpPath: ", tmpPath
                ftp.retrbinary('RETR '+ remoteName, open(tmpPath, 'wb').write)

                # move to final location
                
                cmd = "mv " + tmpPath + " " + dayDir
                runCommand(cmd)
                print "writing file: ", remoteName

                # write latest_data_info
                
                relPath = os.path.join(dateStr, remoteName)
                cmd = "LdataWriter -dir " + options.targetDir \
                      + " -rpath " + relPath \
                      + " -ltime " + str(fileTimeVal) \
                      + " -writer getSatFilesByFtp.py" \
                      + " -dtype nc"
                runCommand(cmd)

                count += 1

    # close ftp connection
                
    ftp.quit()

    if (count == 0):
        print "---->> No files to  download"
        
    print "=========================================================================="
    print "END: getSatFilesByFtp.py at " + str(datetime.datetime.now())
    print "=========================================================================="

    sys.exit(0)


########################################################################
# Parse the command line

def parseArgs():
    
    global options

    defaultTargetDir = os.getenv("DATA_DIR") + "/raw/sat"
    defaultTmpDir = "/tmp/data/raw/sat"
    defaultSubStrings = "VIS_raw.nc,IR.nc,WV.nc"

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
                      default='/pub/incoming/dynamo/meteosat/netcdf',
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
    parser.add_option('--checkNames',
                      dest='checkNames', default='False',
                      action="store_true",
                      help='Check that the file name contains one of the substrings ' +
                      'defined by the --subStrList option. ' +
                      'Each remote file will be checked against the list of strings and ' +
                      'will only be downloaded if a match is found.')
    parser.add_option('--subStrList',
                      dest='subStrList',
                      default=defaultSubStrings,
                      help='Define the list of substrings against which the remote ' 
                      'filenames will be checked. This is a comma-delimited list. ' +
                      ' The default list is: "' + defaultSubStrings + '"')

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
