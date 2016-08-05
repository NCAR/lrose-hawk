#!/usr/bin/env python

#===========================================================================
#
# Plot sounding timeseries using matlab
#
#===========================================================================

import os
import sys
import subprocess
from optparse import OptionParser
from stat import *
import time
import datetime
from datetime import date
from datetime import timedelta

def main():

    global options
    global debug
    global dirList

    dataDir = os.getenv("DATA_DIR");

    # parse the command line

    usage = "usage: %prog [options]"
    parser = OptionParser(usage)
    parser.add_option('--debug',
                      dest='debug',
                      default='False',
                      action="store_true",
                      help='Set debugging on')
    parser.add_option('--verbose',
                      dest='verbose',
                      default='False',
                      action="store_true",
                      help='Set verbose debugging on')
    parser.add_option('--startDate',
                      dest='startDate',
                      default='20111001',
                      help='Start date, format: yyyymmdd')
    parser.add_option('--endDate',
                      dest='endDate',
                      default='20120116',
                      help='End date, format: yyyymmdd')
    parser.add_option('--soundingDataDir',
                      dest='soundingDataDir',
                      default=os.path.join(dataDir, 'matlab'),
                      help='Path to sounding data directories')
    parser.add_option('--siteSubDir',
                      dest='siteSubDir',
                      default=os.path.join(dataDir, 'gan'),
                      help='Subdirectory for this site')
    parser.add_option('--siteName',
                      dest='siteName',
                      default=os.path.join(dataDir, 'Gan'),
                      help='Full name for this site')
    parser.add_option('--outputImageDir',
                      dest='outputImageDir',
                      default=os.path.join(dataDir, 'matlab/catalogimages/'),
                      help='Path to output image files')
    parser.add_option('--matlabPath',
                      dest='matlabPath',
                      default='/usr/local/MATLAB/R2011a/bin/matlab',
                      help='Path to matlab executable')
    parser.add_option('--minNcFileSize',
                      dest='minNcFileSize',
                      default=50000,
                      help='Minimum size of netCdf files (bytes) - ' + \
                      'smaller files have too few levels')

    (options, args) = parser.parse_args()

    if (options.verbose == True):
        options.debug = True;

    if (options.debug == True):
        print >>sys.stderr, "Running plotSoundingTimeseries.py:"
        print >>sys.stderr, "  startDate: ", options.startDate
        print >>sys.stderr, "  endDate: ", options.endDate
        print >>sys.stderr, "  soundingDataDir: ", options.soundingDataDir
        print >>sys.stderr, "  siteSubDir: ", options.siteSubDir
        print >>sys.stderr, "  siteName: ", options.siteName
        print >>sys.stderr, "  outputImageDir: ", options.outputImageDir
        print >>sys.stderr, "  matlabPath: ", options.matlabPath
        print >>sys.stderr, "  minNcFileSize: ", options.minNcFileSize

    # create mat files for each nc file, if they do not already exist

    siteDataDir = os.path.join(options.soundingDataDir,
                               options.siteSubDir);

    ncDir = os.path.join(siteDataDir, "nc_data")
    ncFileList = loadFileList(ncDir)

    matDir = os.path.join(siteDataDir, "matfiles")
    runCommand("mkdir -p " + matDir)    
    matFileList = loadFileList(matDir)

    missingList = []
    for ncFileName in ncFileList:
        # check the file is large enough
        # small files are not full soundings
        ncFilePath = os.path.join(ncDir, ncFileName)
        fileSize = os.stat(ncFilePath)[ST_SIZE]
        if (int(fileSize) < int(options.minNcFileSize)):
            continue
        ncDatePos = ncFileName.find("201");
        if (ncDatePos >= 0):
            ncTimeStr = ncFileName[ncDatePos:ncDatePos+15]
            found = False;
            for matFileName in matFileList:
                matDatePos = matFileName.find("201");
                if (matDatePos >= 0):
                    matTimeStr = matFileName[ncDatePos:ncDatePos+15]
                    if (matTimeStr == ncTimeStr):
                        found = True;
                        break;
            if (found == False):
                missingList.append(ncFileName)

    for ncFileName in missingList:
        print >>sys.stderr, "Missing mat file for nc file: ", ncFileName

    for ncFileName in missingList:
        ncPos = ncFileName.find(".nc");
        matFileName = ncFileName[:ncPos] + ".mat"
        matFilePath = os.path.join(matDir, matFileName)
        ncFilePath = os.path.join(ncDir, ncFileName)
        print >>sys.stderr, "Missing mat file for nc file: ", ncFilePath
        print >>sys.stderr, "Creating mat file: ", matFilePath
        command = options.matlabPath \
                  + " -nodesktop -nosplash -r \"convert_nc_to_mat(" \
                  + "'" + ncFilePath + "\', " \
                  + "'" + matFilePath + "\'" \
                  + ")\""
        runCommand(command)

    # create combined matfile for data

    combinedMatFile = os.path.join(siteDataDir, "combined.mat")
    matFileList = loadFileList(matDir)
    nMatFiles = len(matFileList)
    if (nMatFiles < 2):
        print >>sys.stderr, "Too few mat files, aborting"
        print >>sys.stderr, "  siteDataDir: ", siteDataDir
        print >>sys.stderr, "  siteName: ", options.siteName
        return
    delimitedList = ""
    for ii in range(nMatFiles):
        delimitedList += matFileList[ii]
        if (ii < nMatFiles - 1):
            delimitedList += ",";

    command = options.matlabPath \
              + " -nodesktop -nosplash -r \"combine_mat(" \
              + "'" + siteDataDir + "\', " \
              + "'" + combinedMatFile + "\', " \
              + "'" + delimitedList + "\'" \
              + ")\""
    
    runCommand(command)

    # make plots for this site

    imageDir = os.path.join(options.outputImageDir, options.siteSubDir);
    imageDir = os.path.join(imageDir, options.endDate);
    runCommand("mkdir -p " + imageDir)    
    command = options.matlabPath \
              + " -nodesktop -nosplash -r \"do_timeseries_plots(" \
              + "'" + combinedMatFile + "\', " \
              + "'" + options.siteName + "\', " \
              + "'" + options.endDate + "\', " \
              + "'" + imageDir + "\'" \
              + ")\""
    
    runCommand(command)

########################################################################
# load up the file list
#
# Files have names like: iss3_sounding.D20111212_171737_P.1.*
#                        male_sounding.43555_201112142332.cls.*
#                        gansondewnpnM1.b1.20111217.023400.*

def loadFileList(matDir):

    # check if file has already been retrieved

    fileList = []
    dirList = os.listdir(matDir)
    fileList = []
    for entryName in dirList:
        entryPath = os.path.join(matDir, entryName)
        if (os.path.isfile(entryPath) == True):
            fileName = entryName
            (iret, year, month, day, hour, min, sec) \
                   = getDateFromFileName(fileName)
            if (iret == 0):
                datePos = fileName.find("201");
                dateStr = fileName[datePos:datePos+8]
                if ((int(dateStr) >= int(options.startDate)) and
                    (int(dateStr) <= int(options.endDate))):
                    fileList.append(fileName)

    # build a sorted list
    
    seqDict = {}
    for fileName in fileList:
        datePos = fileName.find("201");
        key = fileName[datePos:datePos+13]
        seqDict[key] = fileName

    keylist = seqDict.keys()
    keylist.sort()
    fileList = []
    for key in keylist:
        fileList.append(seqDict[key])

    for fileName in fileList:
        if (options.verbose == True):
            print >>sys.stderr, "-->> found file: ", fileName

    return fileList
            
########################################################################
# Run date and time from file name

def getDateFromFileName(fileName):

    iret = 0
    
    datePos = fileName.find("201")
    if (datePos < 0):
        return (-1, 0, 0, 0, 0, 0, 0)
    
    delimiter = fileName[datePos+8:datePos+9]
    yearStr = fileName[datePos:datePos+4]
    monthStr = fileName[datePos+4:datePos+6]
    dayStr = fileName[datePos+6:datePos+8]

    if (delimiter.isdigit()):
        hourStr = fileName[datePos+8:datePos+10]
        minStr = fileName[datePos+10:datePos+12]
        secStr = "00"
    elif (delimiter == "." or delimiter == "_"):
        hourStr = fileName[datePos+9:datePos+11]
        minStr = fileName[datePos+11:datePos+13]
        secStr = fileName[datePos+13:datePos+15]
    else:
        iret = -1
        hourStr = "00"
        minStr = "00"
        secStr = "00"

    year = int(yearStr)
    month = int(monthStr)
    day = int(dayStr)
    hour = int(hourStr)
    min = int(minStr)
    sec = int(secStr)

    return (iret, year, month, day, hour, min, sec)

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
# Run - entry point

if __name__ == "__main__":
   main()
