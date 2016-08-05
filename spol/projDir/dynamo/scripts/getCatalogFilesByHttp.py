#!/usr/bin/env python

#===========================================================================
#
# Download Catalog data using http
#
#===========================================================================

import os
import sys
import time
import datetime
from datetime import timedelta
import string
import httplib
import base64
import subprocess
from optparse import OptionParser
from stat import *

def main():

    global options
    global tmpDir
    global startTimeStr
    global count

    count = 0

    # parse the command line

    parseArgs()

    # initialize
    
    beginString = "BEGIN: getCatalogFilesByHttp.py"
    today = datetime.datetime.now()
    beginString += " at " + str(today)
    
    print "========================================================"
    print beginString
    print "========================================================"

    # create tmp dir if necessary

    if not os.path.exists(options.tmpDir):
        runCommand("mkdir -p " + options.tmpDir)

    # open http connection

    if (options.debug == True):
        print >>sys.stderr, "httpServer: '%s'"% options.httpServer
    
    conn = httplib.HTTPConnection(options.httpServer)
    
    # get current time

    nowTime = time.gmtime()
    now = datetime.datetime(nowTime.tm_year, nowTime.tm_mon, nowTime.tm_mday,
                            nowTime.tm_hour, nowTime.tm_min, nowTime.tm_sec)
    nowTimeStr = now.strftime("%Y%m%d%H%M%S")
    
    # compute start time

    pastSecs = timedelta(0, int(options.pastSecs))
    startTime = now - pastSecs
    startTimeStr = startTime.strftime("%Y%m%d%H%M%S")
    startDateStr = startTime.strftime("%Y%m%d")

    if (options.debug == True):
        print >>sys.stderr, "  time now: ", nowTimeStr
        print >>sys.stderr, "  getting data after time: ", startTimeStr
        print >>sys.stderr, "  getting data after date: ", startDateStr

    # get dir list from server

    conn.request("GET", options.sourceDir + "/")
    response = conn.getresponse()
    if (int(response.status) != 200):
        print >>sys.stderr, "====>> response status, reason", \
              response.status, response.reason
        print >>sys.stderr, "ERROR reading index.html"
        sys.exit(1)
        
    lines = response.read().split('\n')
    dateList = []
    for line in lines:
        datePos = line.find("201")
        if (datePos > 0):
            dateStr = line[datePos:datePos+8]
            if (options.verbose == True):
                print >>sys.stderr, "Found date dir: ", dateStr
            if (int(dateStr) >= int(startDateStr)):
                # date is after start date, do process
                dateList.append(dateStr)

    # loop through dates

    for dateStr in dateList:

        if (options.debug == True):
            print >>sys.stderr, "Processing date dir: ", dateStr

        dateDirPath = os.path.join(options.sourceDir, dateStr) + "/"
        conn.request("GET", dateDirPath)
        response = conn.getresponse()
        if (response.status != 200):
            print >>sys.stderr, "====>> response status, reason", \
                  response.status, response.reason
            continue
        lines = response.read().split('\n')

        # build up file name list

        fileNames = []
        for line in lines:
            if (line.find(dateStr) < 0):
                continue
            hrefPos = line.find("href=")
            closeBracketPos = line.find(">", hrefPos)
            openBracketPos = line.find("<", closeBracketPos)
            if (closeBracketPos > 0 and openBracketPos > 0):
                fileName = line[closeBracketPos+1:openBracketPos]
                if (fileName.find(dateStr) >= 0):
                    fileNames.append(fileName)

        for fileName in fileNames:
            datePos = fileName.find(dateStr)
            dateTimeStr = fileName[datePos:datePos+12] + "00"
            if (options.verbose == True):
                print >>sys.stderr, "Checking file name: ", fileName
                print >>sys.stderr, "       dateTimeStr: ", dateTimeStr
            
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
                            
            if (fileAlreadyHere == False):

                # read file using http

                print "====>> Getting file: ", fileName

                conn.request("GET", dateDirPath + fileName)
                response = conn.getresponse()
                if (int(response.status) != 200):
                    print >>sys.stderr, "====>> response status, reason",\
                          response.status, response.reason
                    print >>sys.stderr, "ERROR reading file: ", fileName
                    continue

                # store in tmp
                
                tmpPath = os.path.join(options.tmpDir, fileName)
                if (options.verbose == True):
                    print >>sys.stderr, "retrieving file, storing as tmpPath: ", tmpPath
                    
                tmpFile = open(tmpPath, 'w')
                tmpFile.write(response.read())
                tmpFile.close()
                
                # move to final location

                cmd = "mv " + tmpPath + " " + dayDir
                runCommand(cmd)
                finalPath = os.path.join(dayDir, fileName)
                print >>sys.stderr, "Renamed to final path: ", finalPath

                # write latest_data_info
                
                relPath = os.path.join(dateStr, fileName)
                cmd = "LdataWriter -dir " + options.targetDir \
                      + " -rpath " + relPath \
                      + " -ltime " + str(dateTimeStr) \
                      + " -writer getLtgDataByHttp.py" \
                      + " -dtype " + options.dataType
                runCommand(cmd)

                count += 1

    if (count == 0):
        print "---->> No files to  download"
    else:
        print "---->> downloaded n files: ", count
        
    print "=========================================================="
    print "END: getCatalogFilesByHttp.py at " + str(datetime.datetime.now())
    print "=========================================================="

    sys.exit(0)


########################################################################
# Get files from this dir

def getFilesFromDir(http, dirName, dirPath):

    global count
    
    # get file list from server
    
    http.chdir(dirPath)
    fileList = http.listdir()

    if (options.debug == True):
        print "Processing dir: ", dirPath

    # go through files in list

    for fileName in fileList:

        fileStat = http.lstat(fileName)
        remoteSize = fileStat.st_size
        
        if (options.debug == True):
            print "  fileName: ", fileName
            print "  fileStat: ", fileStat
            print "  remoteSize: ", remoteSize

        # check name against substring list if needed
        
        if (checkFileName(fileName) == False):
            continue

        # process this file
	# find the date/time section of the filename,
        # which starts with ".20"
	
	dateIndex = fileName.find('.20')
        if (dateIndex < 0):
            continue
        
        dateStr = fileName[dateIndex + 1: dateIndex+9]
        dateTimeStr = fileName[dateIndex + 1: dateIndex+13] + '00'
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
                            
            if (fileAlreadyHere == False):

                # get file, store in tmp
                
                tmpPath = os.path.join(options.tmpDir, fileName)
                if (options.debug == True):
                    print "retrieving file, storing as tmpPath: ", tmpPath
                http.get(fileName, tmpPath)

                # move to final location
                
                cmd = "mv " + tmpPath + " " + dayDir
                runCommand(cmd)
                print "writing file: ", fileName

                # write latest_data_info
                
                relPath = os.path.join(dateStr, fileName)
                cmd = "LdataWriter -dir " + options.targetDir \
                      + " -rpath " + relPath \
                      + " -ltime " + str(fileTimeVal) \
                      + " -writer getCatalogFilesByHttp.py" \
                      + " -dtype " + options.dataType
                runCommand(cmd)

                count += 1

                time.sleep(float(options.sleepSecs))


########################################################################
# Parse the command line

def parseArgs():
    
    global options

    defaultTargetDir = os.getenv("DATA_DIR") + "/tmp/catalog/revelle_posn"
    defaultTmpDir = os.getenv("DATA_DIR") + "/tmp/raw/catalog"
    defaultSubStrings = "txt"

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
    parser.add_option('--httpServer',
                      dest='httpServer',
                      default='catalog1.eol.ucar.edu',
                      help='Name of http server host')
    parser.add_option('--sourceDir',
                      dest='sourceDir',
                      default='/dynamo/data/revelle/',
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
        print >>sys.stderr, "  httpServer: ", options.httpServer
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
