#!/usr/bin/env python

#===========================================================================
#
# Put matlab result images to catalog
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
    
    scriptName = "putMatlabResultsToCatalog.py"
    beginString = "BEGIN: " + scriptName
    today = datetime.datetime.now()
    beginString += " at " + str(today)

    if (options.debug == True):
        print >>sys.stderr, "=============================================="
        print >>sys.stderr, beginString
        print >>sys.stderr, "=============================================="

    # compute valid time string
    
    startIndex = options.fileName.find("_20")
    if (startIndex < 0):
        print >>sys.stderr, "ERROR - cannot find date/time"
        print >>sys.stderr, "  fileName: ", options.fileName
        sys.exit(1)

    yyyymmdd = options.fileName[startIndex+1:startIndex+9]
    hhmmss = options.fileName[startIndex+10:startIndex+16]
    validTimeStr = yyyymmdd + hhmmss
    
    print "validTimeStr: ", validTimeStr

    # compute full path of image
    
    fullFilePath = os.path.join(options.imageDir, options.relDataPath);

    print "fullFilePath: ", fullFilePath
    print "file exists: ", os.path.exists(fullFilePath)

    # compute catalog file name

    if (options.relDataPath.find("repoh") >= 0):

        if (options.fileName.find("repoh_all") >= 0):
            catalogName = "research.SPOL_Ka_HUMIDITY." \
                          + validTimeStr + ".Daily_profile.png"
        else:
            catalogName = "research.SPOL_Ka_HUMIDITY." \
                          + validTimeStr + ".3hr_profile.png"

    else:

        stationName = ""
        if (options.relDataPath.find("revelle") >= 0):
            stationName = "Revelle"
        elif (options.relDataPath.find("diego") >= 0):
            stationName = "DiegoGarcia"
        elif (options.relDataPath.find("male") >= 0):
            stationName = "Male"
        elif (options.relDataPath.find("gan") >= 0):
            stationName = "Gan"
        else:
            sys.exit(0) # not needed
            
        fieldName = ""
        if (options.fileName.find("ahum") >= 0):
            fieldName = "VaporDensity"
        elif (options.fileName.find("timemean") >= 0):
            fieldName = "VaporDensityDeviation"
        elif (options.fileName.find("uwindanom") >= 0):
            fieldName = "ZonalWindAnomaly"
        elif (options.fileName.find("vwindanom") >= 0):
            fieldName = "MeridionalWindAnomaly"
        elif (options.fileName.find("Tanom") >= 0):
            fieldName = "TemperatureAnomaly"
        else:
            sys.exit(0) # not needed

        catalogName = "research.Hourly_Time_Series." \
                      + validTimeStr + "." + stationName \
                      + "_" + fieldName + ".png"

    print "-->> catalogName: ", catalogName

    # NOTE TO CHRIS
    # BALING OUT FOR REPOH DATA
    # REMOVE THIS WHEN REPOH READY FOR PRIME TIME
    
    #if (options.relDataPath.find("repoh") >= 0):
    #    print "===>>> IGNORING REPOH FILE <<===="
    #    print "===>>> EDIT script to handle REPOH OUTPUT <<===="
    #    sys.exit(0)

    # put the file

    putFile(fullFilePath, catalogName)
    
    if (options.debug == True):
        print >>sys.stderr, "==================================================="
        print >>sys.stderr, \
              "END: " + scriptName + " at " + str(datetime.datetime.now())
        print >>sys.stderr, "==================================================="

    sys.exit(0)

########################################################################
# Put the specified file

def putFile(filePath, catalogName):

    if (options.debug == True):
        print >>sys.stderr, "Handling file: ", filePath
        print >>sys.stderr, "  catalogName: ", catalogName

    # create tmp dir if necessary
    
    tmpDir = "/tmp/data/images/sounding_timeseries"
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
    parser.add_option('--rel_data_path',
                      dest='relDataPath',
                      default='unknown',
                      help='Relative path of image file')

    (options, args) = parser.parse_args()

    if (options.debug == True):
        print >>sys.stderr, "Options:"
        print >>sys.stderr, "  debug? ", options.debug
        print >>sys.stderr, "  validTime: ", options.validTime
        print >>sys.stderr, "  imageDir: ", options.imageDir
        print >>sys.stderr, "  relDataPath: ", options.relDataPath
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
