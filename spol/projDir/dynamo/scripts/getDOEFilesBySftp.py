#!/usr/bin/env python

#===========================================================================
#
# Download DOE data using sftp
#
#===========================================================================

import os
import sys
import time
import datetime
from datetime import timedelta
import string
import paramiko
import subprocess
from optparse import OptionParser
from stat import *

def main():

    global options
    global sftpUser
    global sftpPassword
    global skipFtp
    global tmpDir

    sftpUser = "sellis"
    sftpPassword = "doe4dynam0!"
    skipFtp = 0

    # parse the command line

    parseArgs()

    # initialize
    
    beginString = "BEGIN: getDOEFilesBySFtp.py"
    today = datetime.datetime.now()
    beginString += " at " + str(today)
    
    if (options.force == True):
        skipFtp = 0
        beginString += " ( forcing transfer )"

    print "========================================================"
    print beginString
    print "========================================================"

    if (skipFtp):
        print "skipping FTP of", options.sourceDir, " to", options.targetDir
        sys.exit(0)

    # create tmp dir if necessary

    if not os.path.exists(options.tmpDir):
        runCommand("mkdir -p " + options.tmpDir)

    # open sftp connection

    options.sshPort = int(options.sshPort) 
    if (options.debug == True):
        print >>sys.stderr, "sftpServer: '%s'"% options.sftpServer
        print >>sys.stderr, "sshPort: %d" % options.sshPort
        print >>sys.stderr, "sftpUser:'%s'" % sftpUser
        print >>sys.stderr, "sftpPassword: '%s'" % sftpPassword
    
    transport = paramiko.Transport((options.sftpServer, int(options.sshPort)))
    transport.connect(username = sftpUser, password = sftpPassword)
    sftp = paramiko.SFTPClient.from_transport(transport)
    
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
    
    sftp.chdir(options.sourceDir)
    fileList = sftp.listdir()

    if (options.debug == True):
        print "dir list: ", fileList

    # go through files in list

    count = 0
    for fileName in fileList:
        
        fileStat = sftp.lstat(fileName)
        remoteSize = fileStat.st_size

        if (options.debug == True):
            print "  fileName: ", fileName
            print "  fileStat: ", fileStat
            print "  remoteSize: ", remoteSize

        # check name against substring list if needed
        
        if (checkFileName(fileName) == False):
            continue

        # process this file
	# find the date/time section of the filename, using the file format 
	# gansondewnpnM1.b1.20110922.060100.cdf
	
	dateIndex = fileName.find('.',fileName.find('.')+1)+1
	dateStr = fileName[dateIndex: dateIndex+8]
	
        dateTimeStr = dateStr + fileName[dateIndex+9:dateIndex+15]
        if (options.debug == True):
            print "  dateStr: ", dateStr
            print "  dateTimeStr: ", dateTimeStr

        startTimeVal = int(startTimeStr)
        fileTimeVal = int(dateTimeStr)

        if (options.debug == True):
            print "  startTimeVal: ", startTimeVal
            print "   fileTimeVal: ", fileTimeVal

        doGet = False
        if (fileTimeVal >= startTimeVal):
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
                if (options.debug == True):
                    print "  -->> remoteSize: ", remoteSize
                    print "  -->> localSize: ", localSize
                if (int(localSize) == int(remoteSize)):
                    fileAlreadyHere = True
                else:
                    if (options.debug == True):
                        print "  -->> File size has changed"
                        print "  -->>   Need to retrieve again"
            
            if (options.debug == True):
                print "fileAlreadyHere: ", fileAlreadyHere
                            
            if ((fileAlreadyHere == False) or (options.force == True)):

                # get file, store in tmp
                
                tmpPath = os.path.join(options.tmpDir, fileName)
                if (options.debug == True):
                    print "retrieving file, storing as tmpPath: ", tmpPath
                sftp.get(fileName, tmpPath)

                # move to final location
                
                cmd = "mv " + tmpPath + " " + dayDir
                runCommand(cmd)
                print "writing file: ", fileName

                # write latest_data_info
                
                relPath = os.path.join(dateStr, fileName)
                cmd = "LdataWriter -dir " + options.targetDir \
                      + " -rpath " + relPath \
                      + " -ltime " + str(fileTimeVal) \
                      + " -writer getDOEFilesByFtp.py" \
                      + " -dtype " + options.dataType
                runCommand(cmd)

                count += 1

                time.sleep(float(options.sleepSecs))

    # close ftp connection
                
    sftp.close()

    if (count == 0):
        print "---->> No files to  download"
        
    print "=========================================================="
    print "END: getDOEFilesByFtp.py at " + str(datetime.datetime.now())
    print "=========================================================="

    sys.exit(0)


########################################################################
# Parse the command line

def parseArgs():
    
    global options

    defaultTargetDir = os.getenv("DATA_DIR") + "/raw/doe"
    defaultTmpDir = os.getenv("DATA_DIR") + "/tmp/raw/doe"
    defaultSubStrings = "RAW"

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
    parser.add_option('--sftpServer',
                      dest='sftpServer',
                      default='123.176.23.226',
                      help='Name of sftp server host')
    parser.add_option('--sshPort',
                      dest='sshPort',
                      default=22222,
                      help='SSH port for access to sftp server')
    parser.add_option('--sourceDir',
                      dest='sourceDir',
                      default='/usr/iris_data/product_raw',
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
    parser.add_option('--sleepSecs',
                      dest='sleepSecs',
                      default=1,
                      help='Time in secs to sleep between files')
    parser.add_option('--dataType',
                      dest='dataType',
                      default="raw",
                      help='Type of data for DataMapper')

    (options, args) = parser.parse_args()

    if (options.verbose == True):
        options.debug = True

    if (options.debug == True):
        print >>sys.stderr, "Options:"
        print >>sys.stderr, "  debug? ", options.debug
        print >>sys.stderr, "  force? ", options.force
        print >>sys.stderr, "  sftpServer: ", options.sftpServer
        print >>sys.stderr, "  sourceDir: ", options.sourceDir
        print >>sys.stderr, "  tmpDir: ", options.tmpDir
        print >>sys.stderr, "  pastSecs: ", options.pastSecs
        print >>sys.stderr, "  sleepSecs: ", options.sleepSecs
        print >>sys.stderr, "  dataType: ", options.dataType

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
