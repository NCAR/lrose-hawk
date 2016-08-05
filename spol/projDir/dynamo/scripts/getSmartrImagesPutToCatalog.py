#!/usr/bin/env python

#======================================================================
#
# Download SMARTR images using sftp
# and put them to the catalog
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
from stat import *
import ftplib

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
    
    beginString = "BEGIN: getSmartrImagesPutToCatalog.py"
    today = datetime.datetime.now()
    beginString += " at " + str(today)
    
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
        print >>sys.stderr, "sourceServer: ", options.sourceServer
        print >>sys.stderr, "  sshPort: ", options.sshPort
        print >>sys.stderr, "  sftpUser: ", sftpUser
        print >>sys.stderr, "  sftpPassword: ", sftpPassword
    
    transport = paramiko.Transport((options.sourceServer, options.sshPort))
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

    # go through files in list

    count = 0
    for fileName in fileList:

        if (options.verbose == True):
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
        if (options.verbose == True):
            print "  dateStr: ", dateStr
            print "  dateTimeStr: ", dateTimeStr

        startTimeVal = int(startTimeStr)
        fileTimeVal = int(dateTimeStr)

        if (options.verbose == True):
            print "  startTimeVal: ", startTimeVal
            print "   fileTimeVal: ", fileTimeVal

        if (fileTimeVal >= startTimeVal):
        
            # process this file

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
                    if (localName == fileName):
                        fileAlreadyHere = True

            if (options.verbose == True):
                print "fileAlreadyHere: ", fileAlreadyHere
                            
            if (fileAlreadyHere == False):

                # get file, store in tmp

                tmpPath = os.path.join(options.tmpDir, fileName)
                if (options.debug == True):
                    print "retrieving file, storing as tmpPath: ", tmpPath
                sftp.get(fileName, tmpPath)

                # move to final location
                
                finalPath = os.path.join(dayDir, fileName)
                cmd = "mv " + tmpPath + " " + finalPath
                runCommand(cmd)
                print "writing local file: ", fileName
                print "              path: ", finalPath

                # send this file to the catalog
                
                sendToCatalog(fileName, finalPath, dateTimeStr)
                count += 1

    # close ftp connection
                
    sftp.close()

    if (count == 0):
        print "---->> No files to  download"
        
    print "============================================================="
    print "END: getSmartrImagesPutToCatalog.py at " + str(datetime.datetime.now())
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
    parser.add_option('--sourceServer',
                      dest='sourceServer',
                      default='27.114.136.18',
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
    parser.add_option('--targetServer',
                      dest='targetServer',
                      default='catalog1.eol.ucar.edu',
                      help='Name of ftp catalog server')

    (options, args) = parser.parse_args()

    if (options.verbose == True):
        options.debug = True

    if (options.debug == True):
        print >>sys.stderr, "Options:"
        print >>sys.stderr, "  debug? ", options.debug
        print >>sys.stderr, "  sourceServer: ", options.sourceServer
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

#===========================================================================
#
# Handle a file which arrived
#
#===========================================================================

def sendToCatalog(fileName, filePath, dateTimeStr):

    global ftpUser
    global ftpPassword
    global ftpDebugLevel

    ftpUser = "anonymous"
    ftpPassword = ""

    print "filePath: ", filePath
    print "file exists: ", os.path.exists(filePath)

    # compute catalog file name

    prodSeq = fileName[-6:-4]
    fieldName = ""
    
    if (fileName.find("PPI_Z_005_300") == 0):
        fieldName = "smartr_DBZ_SUR"
    elif (fileName.find("PPI_Z_029_150") == 0):
        fieldName = "smartr_DBZ_PPI_3deg"
    elif (fileName.find("PPI_V_029_150") == 0):
        fieldName = "smartr_VEL_PPI_3deg"
    elif (fileName.find("CAP_Z_040_150") == 0):
        fieldName = "smartr_DBZ_CAPPI_4km"
    elif (fileName.find("CAP_V_040_150") == 0):
        fieldName = "smartr_VEL_CAPPI_4km"
    elif (fileName.find("CAP_Z_080_150") == 0):
        fieldName = "smartr_DBZ_CAPPI_8km"
    elif (fileName.find("CAP_V_080_150") == 0):
        fieldName = "smartr_VEL_CAPPI_8km"
    elif (fileName.find("RHI_Z_147") == 0):
        fieldName = "smartr_DBZ_RHI_147deg"
    else:
        return # not needed

    catalogName = "research.SMARTR." + dateTimeStr + "." + fieldName + ".gif"
    print "-->> catalogName: ", catalogName

    # put the file

    putFile(filePath, catalogName)
    
    return

########################################################################
# Put the specified file

def putFile(filePath, catalogName):

    if (options.debug == True):
        print >>sys.stderr, "Handling file: ", filePath
        print >>sys.stderr, "  catalogName: ", catalogName

    # create tmp dir if necessary
    
    tmpDir = "/tmp/data/images/smartr"
    if not os.path.exists(tmpDir):
        runCommand("mkdir -p " + tmpDir)

    # copy the file to the tmp directory

    tmpPath = os.path.join(tmpDir, catalogName)
    cmd = "cp " + filePath + " " + tmpPath
    runCommand(cmd)

    # send the file to the catalog
    
    ftpFile(catalogName, tmpPath)

    # remove the tmp file
    
    cmd = "/bin/rm " + tmpPath
    runCommand(cmd)
    
    return 0
    
########################################################################
# Ftp the file

def ftpFile(fileName, filePath):

    # set ftp debug level

    if (options.debug == True):
        ftpDebugLevel = 2
    else:
        ftpDebugLevel = 0
    
    targetDir = "pub/incoming/catalog/dynamo/"
    ftpServer = options.targetServer
    
    # open ftp connection
    
    ftp = ftplib.FTP(ftpServer, ftpUser, ftpPassword)
    ftp.set_debuglevel(ftpDebugLevel)
    
    # go to target dir

    if (options.debug == True):
        print >>sys.stderr, "ftp cwd to: " + targetDir
    
    ftp.cwd(targetDir)

    # put the file

    if (options.debug == True):
        print >>sys.stderr, "putting file: ", filePath

    fp = open(filePath, 'rb')
    ftp.storbinary('STOR ' + fileName, fp)
    
    # close ftp connection
                
    ftp.quit()

    return

########################################################################
# kick off main method

if __name__ == "__main__":

   main()

