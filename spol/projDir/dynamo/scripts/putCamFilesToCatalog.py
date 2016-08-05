#!/usr/bin/env python

#===========================================================================
#
# Put latest camera images to catalog
#
#===========================================================================

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
    
    beginString = "BEGIN: putCamFilesToCatalog.py"
    today = datetime.datetime.now()
    beginString += " at " + str(today)

    if (options.debug == True):
        print >>sys.stderr, "=============================================="
        print >>sys.stderr, beginString
        print >>sys.stderr, "=============================================="

    # create tmp dir if necessary
    
    if not os.path.exists(options.tmpDir):
        runCommand("mkdir -p " + options.tmpDir)

    # put latest file for each direction each of the files

    putFile("E_latest.jpg", "camE")
    putFile("N_latest.jpg", "camN")
    putFile("S_latest.jpg", "camS")
    putFile("W_latest.jpg", "camW")
    
    if (options.debug == True):
        print >>sys.stderr, "==================================================="
        print >>sys.stderr, \
              "END: getSatFilesByFtp.py at " + str(datetime.datetime.now())
        print >>sys.stderr, "==================================================="

    sys.exit(0)

########################################################################
# Put the specified file

def putFile(fileName, label):

    # compute the latest image file path

    filePath = os.path.join(options.sourceDir, fileName)

    modTime = time.gmtime(os.stat(filePath)[ST_MTIME])
    year = int(modTime[0])
    month = int(modTime[1])
    day = int(modTime[2])
    hour = int(modTime[3])
    min = int(modTime[4])
    sec = int(modTime[5])

    modTimeStr = "%.4d%.2d%.2d%.2d%.2d%.2d" % (year, month, day, hour, min, sec)
    catalogName = "research.SPOL_CAM." + modTimeStr + "." + label + ".jpg"
    
    if (options.debug == True):
        print >>sys.stderr, "Handling file: ", filePath
        print >>sys.stderr, "  catalogName: ", catalogName

    # get current time

    nowTime = time.gmtime()
    now = datetime.datetime(nowTime.tm_year, nowTime.tm_mon, nowTime.tm_mday,
                            nowTime.tm_hour, nowTime.tm_min, nowTime.tm_sec)
    nowTimeStr = now.strftime("%Y%m%d%H%M%S")

    # compute start time

    maxAgeSecs = timedelta(0, int(options.maxAgeSecs))
    checkTime = now - maxAgeSecs
    checkTimeStr = checkTime.strftime("%Y%m%d%H%M%S")

    if (options.debug == True):
        print >>sys.stderr, "  time now: ", nowTimeStr
        print >>sys.stderr, "  only getting data after: ", checkTimeStr

    checkTimeVal = int(checkTimeStr)
    modTimeVal = int(modTimeStr)

    if (options.debug == True):
        print >>sys.stderr, "  checkTimeVal: ", checkTimeVal
        print >>sys.stderr, "   modTimeVal: ", modTimeVal
        
    if (modTimeVal < checkTimeVal):
        if (options.debug == True):
            print >>sys.stderr, "  file too old, will be ignored"
        return -1
        
    # copy the file to the tmp directory

    tmpPath = os.path.join(options.tmpDir, catalogName)
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

    if (options.verbose == True):
        ftpDebugLevel = 2
    elif (options.debug == True):
        ftpDebugLevel = 1
    else:
        ftpDebugLevel = 0
    
    if (options.debug == True):
        print >>sys.stderr, \
              "FTP: debugLevel, server, user, sourceDir, targetDir:"
        print >>sys.stderr, " ", ftpDebugLevel, options.ftpServer, \
              ftpUser, options.sourceDir, options.targetDir

    # open ftp connection
    
    ftp = ftplib.FTP(options.ftpServer, ftpUser, ftpPassword)
    ftp.set_debuglevel(ftpDebugLevel)
    
    # go to target dir

    if (options.debug == True):
        print >>sys.stderr, "ftp cwd to: " + options.targetDir
    
    ftp.cwd(options.targetDir)

    # put the file

    if (options.debug == True):
        print >>sys.stderr, "putting file: ", filePath

    fp = open(filePath, 'rb')
    ftp.storbinary('STOR ' + fileName, fp)
    
    # close ftp connection
                
    ftp.quit()

    return

########################################################################
# Parse the command line

def parseArgs():
    
    global options

    defaultSourceDir = os.getenv("DATA_DIR") + "/images/spol_cams"
    defaultTargetDir = "pub/incoming/catalog/dynamo/"
    defaultTmpDir = "/tmp/data/images/spol_cams"

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
    parser.add_option('--ftpServer',
                      dest='ftpServer',
                      default='catalog.gate.rtf',
                      help='Name of ftp server host')
    parser.add_option('--sourceDir',
                      dest='sourceDir',
                      default=defaultSourceDir,
                      help='Path of source directory')
    parser.add_option('--targetDir',
                      dest='targetDir',
                      default=defaultTargetDir,
                      help='Path of target directory on server')
    parser.add_option('--tmpDir',
                      dest='tmpDir',
                      default=defaultTmpDir,
                      help='Path of tmp directory')
    parser.add_option('--maxAgeSecs',
                      dest='maxAgeSecs',
                      default=300,
                      help='Only allow images less than this age (secs)')

    (options, args) = parser.parse_args()

    if (options.verbose == True):
        options.debug = True

    if (options.debug == True):
        print >>sys.stderr, "Options:"
        print >>sys.stderr, "  debug? ", options.debug
        print >>sys.stderr, "  ftpServer: ", options.ftpServer
        print >>sys.stderr, "  sourceDir: ", options.sourceDir
        print >>sys.stderr, "  targetDir: ", options.targetDir
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
# kick off main method

if __name__ == "__main__":

   main()
