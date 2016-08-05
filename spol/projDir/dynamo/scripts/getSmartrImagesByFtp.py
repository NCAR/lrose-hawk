#!/usr/bin/env python

#======================================================================
#
# Download SMARTR images using sftp
#
#======================================================================

import os
import sys
import time
import datetime
from datetime import timedelta
import string
import paramiko
import subprocess
from optparse import OptionParser

def main():

    global options
    global sftpUser
    global sftpPassword
    global skipFtp
    global tmpDir

    sftpUser = "operator"
    sftpPassword = "xxxxxx"
    skipFtp = 0

    # parse the command line

    parseArgs()

    # initialize
    
    beginString = "BEGIN: getSmartrImagesFtp.py"
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

    # open sftp connection

    if (options.debug == True):
        print >>sys.stderr, "sftpServer: ", options.sftpServer
        print >>sys.stderr, "sshPort: ", options.sshPort
        print >>sys.stderr, "sftpUser: ", sftpUser
        print >>sys.stderr, "sftpPassword: ", sftpPassword
    
    transport = paramiko.Transport((options.sftpServer, options.sshPort))
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

    # build up a dictionary using the image number

    #seqDict = {}
    #for remoteName in fileList:
    #    key = remoteName[24:28]
    #    seqDict[key] = remoteName

    # build a sorted list
    
    #keylist = seqDict.keys()
    #keylist.sort()
    #sortedList = []
    #for key in keylist:
    #    sortedList.append(seqDict[key])

    # compute cappi or rhi product number in the sequence
    # so that we can later figure out where we are in the sequence

    #productSeqNum = 0
    #prevProductType = "NONE"

    #prodSeqNums = {}
    #for fileName in sortedList:
    #    productType = "NONE"
    #    if (fileName.find("PPI") > 0):
    #        productType = "PPI"
    #        if (prevProductType == "PPI"):
    #            productSeqNum = int(productSeqNum) + 1
    #        else:
    #            productSeqNum = 0
    #    elif (fileName.find("CAP") > 0):
    #        productType = "CAP"
    #        if (prevProductType == "CAP"):
    #            productSeqNum = int(productSeqNum) + 1
    #        else:
    #            productSeqNum = 0
    #    elif (fileName.find("RHI") > 0):
    #        productType = "RHI"
    #        if (prevProductType == "RHI"):
    #            productSeqNum = int(productSeqNum) + 1
    #        else:
    #            productSeqNum = 0

    #    prevProductType = productType
    #    prodSeqNums[fileName] = "%.2d" % (productSeqNum)

    #    if (options.verbose == True):
    #        print "fileName, productType, productSeqNum: ", \
    #              fileName, ", ", productType, ", ", productSeqNum


    # go through files in sorted list

    #count = 0
    #for fileName in sortedList:

    # go through files in list

    count = 0
    for fileName in fileList:

        if (options.debug == True):
            print "  fileName: ", fileName

        # check name against substring list if needed
        
        if (checkFileName(fileName) == False):
            continue
        if (fileName.find("smart") == 0):
            # old style file
            continue

        # check file time
            
        dateStr = fileName[-18:-10]
        dateTimeStr = fileName[-18:-4]
        if (options.debug == True):
            print "  dateStr: ", dateStr
            print "  dateTimeStr: ", dateTimeStr

        startTimeVal = int(startTimeStr)
        fileTimeVal = int(dateTimeStr)

        if (options.debug == True):
            print "  startTimeVal: ", startTimeVal
            print "   fileTimeVal: ", fileTimeVal

        if (fileTimeVal >= startTimeVal):
        
            # process this file

            dayDir = os.path.join(options.targetDir, dateStr)
            if (options.debug == True):
                print "dayDir: ", dayDir

            # create day dir if necessary

            if not os.path.exists(dayDir):
                runCommand("mkdir -p " + dayDir)

            # check if file has already been retrieved
            
            fileAlreadyHere = False
            for root, dirs, localfiles in os.walk(dayDir):
                for localName in localfiles:
                    if (localName == fileName):
                        fileAlreadyHere = True

            if (options.debug == True):
                print "fileAlreadyHere: ", fileAlreadyHere
                            
            if ((fileAlreadyHere == False) or (options.force == True)):

                # get file, store in tmp

                #baseName = fileName[:-3]
                #extension = fileName[-4:]
                #seqName = baseName + prodSeqNums[fileName] + extension
                #tmpPath = os.path.join(options.tmpDir, seqName)
                tmpPath = os.path.join(options.tmpDir, fileName)
                if (options.debug == True):
                    print "retrieving file, storing as tmpPath: ", tmpPath
                sftp.get(fileName, tmpPath)

                # move to final location
                
                cmd = "mv " + tmpPath + " " + dayDir
                runCommand(cmd)
                print "writing local file: ", fileName

                # write latest_data_info
                
                relPath = os.path.join(dateStr, fileName)
                cmd = "LdataWriter -dir " + options.targetDir \
                      + " -rpath " + relPath \
                      + " -ltime " + str(fileTimeVal) \
                      + " -writer getSmartrFilesByFtp.py" \
                      + " -dtype gif"
                runCommand(cmd)

                count += 1

    # close ftp connection
                
    sftp.close()

    if (count == 0):
        print "---->> No files to  download"
        
    print "============================================================="
    print "END: getSmartrImagesFtp.py at " + str(datetime.datetime.now())
    print "============================================================="

    sys.exit(0)


########################################################################
# Parse the command line

def parseArgs():
    
    global options

    defaultTargetDir = os.getenv("DATA_DIR") + "/images/smartr"
    defaultTmpDir = os.getenv("DATA_DIR") + "/tmp/images/smartr"
    defaultSubStrings = "gif"

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
                      default='smartr',
                      help='Name of sftp server host')
    parser.add_option('--sshPort',
                      dest='sshPort',
                      default=22,
                      help='SSH port for access to sftp server')
    parser.add_option('--sourceDir',
                      dest='sourceDir',
                      default='/usr/iris_data/gifs',
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
        print >>sys.stderr, "  sftpServer: ", options.sftpServer
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
