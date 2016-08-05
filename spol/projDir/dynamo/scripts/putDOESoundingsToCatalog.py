#!/usr/bin/env python

#===========================================================================
#
# Put DOE sounding data to catalog
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

    ftpUser = "anonymous"
    ftpPassword = ""

    # parse the command line

    parseArgs()

    # initialize
    
    beginString = "BEGIN: putDOESoundingsToCatalog.py"
    today = datetime.datetime.now()
    beginString += " at " + str(today)

    if (options.debug == True):
        print >>sys.stderr, "=============================================="
        print >>sys.stderr, beginString
        print >>sys.stderr, "=============================================="

    #   compute valid time string

    validTime = time.gmtime(int(options.validTime))
    year = int(validTime[0])
    month = int(validTime[1])
    day = int(validTime[2])
    hour = int(validTime[3])
    min = int(validTime[4])
    sec = int(validTime[5])
    validDayStr = "%.4d%.2d%.2d" % (year, month, day)
    validTimeStr = "%.4d%.2d%.2d%.2d%.2d%.2d" % (year, month, day, hour, min, sec)

    print "validDayStr: ", validDayStr
    print "validTimeStr: ", validTimeStr

    # compute full path of image
    
    fullFilePath = os.path.join(options.imageDir, validDayStr);
    fullFilePath = os.path.join(fullFilePath, options.fileName);

    print "fullFilePath: ", fullFilePath
    print "file exists: ", os.path.exists(fullFilePath)

    # compute catalog file name

    fieldName = ""
    
    if (options.fileName.find(".cdf") >= 0):
        fieldName = "high_res_data.nc"
    elif (options.fileName.find(".raw.tar") >= 0):
        fieldName = "high_res_data.txt.tar"
    elif (options.fileName.find(".raw") >= 0):
        fieldName = "high_res_data.txt"
    else:
        sys.exit(0) # not needed

    catalogName = "data.DOE_ARM_GAN_soundings." + validTimeStr + "." + fieldName
    print "-->> catalogName: ", catalogName

    # put the file

    putFile(fullFilePath, catalogName)
    
    if (options.debug == True):
        print >>sys.stderr, "==================================================="
        print >>sys.stderr, \
              "END: putDOESoundingsToCatalog.py at " + str(datetime.datetime.now())
        print >>sys.stderr, "==================================================="

    sys.exit(0)

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
    ftpServer = "catalog.gate.rtf"
    
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
    parser.add_option('--unix_time',
                      dest='validTime',
                      default=0,
                      help='Valid time for image')
    parser.add_option('--full_path',
                      dest='imageDir',
                      default='unknown',
                      help='Full path of image file')
    parser.add_option('--file_name',
                      dest='fileName',
                      default='unknown',
                      help='Name of image file')
    parser.add_option('--rel_file_path',
                      dest='relFilePath',
                      default='unknown',
                      help='Relative path of image file')

    (options, args) = parser.parse_args()

    if (options.debug == True):
        print >>sys.stderr, "Options:"
        print >>sys.stderr, "  debug? ", options.debug
        print >>sys.stderr, "  validTime: ", options.validTime
        print >>sys.stderr, "  imageDir: ", options.imageDir
        print >>sys.stderr, "  relFilePath: ", options.relFilePath
        print >>sys.stderr, "  fileName: ", options.fileName

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
