#!/usr/bin/env python

#===========================================================================
#
# Download ltg files from web site using http
#
#===========================================================================

import os
import sys
import time
import datetime
from datetime import timedelta
import string
import subprocess
from optparse import OptionParser
import httplib
import base64

def main():

    global options

    # parse the command line

    parseArgs()

    # initialize
    
    beginString = "BEGIN: getFalconTracksByHttp"
    today = datetime.datetime.now()
    beginString += " at " + str(today)
    
    print "==========================================================="
    print beginString
    print "==========================================================="


    # open http connection
    
# no timeout in Python 2.4.3
#    conn = httplib.HTTPConnection(options.httpServer, options.httpPort, False, options.httpTimeout)
    
    try:
        conn = httplib.HTTPConnection(options.httpServer, options.httpPort)
    except:
	print >>sys.stderr, "could not connect to %s:%d" % (options.httpServer, options.httpPort)
	sys.exit(1)

    if (options.verbose == True):
        print >>sys.stderr, 'server =', options.httpServer
        print >>sys.stderr, "port = ", options.httpPort
    
    # grab the flight track file:
    
    try:
	conn.request("GET", options.trackTextFile, "")
    except:
	print >>sys.stderr, "could not fetch %s" % (options.trackTextFile)
	sys.exit(1)
    response = conn.getresponse()
    if (options.debug == True):
        print >>sys.stderr, "====>> response status, reason", response.status, response.reason
    if (int(response.status) != 200):
        print >>sys.stderr, "ERROR reading %s"%  options.trackTextFile
        sys.exit(1)
        
    # get current time

    nowTime = time.gmtime()
    now = datetime.datetime(nowTime.tm_year, nowTime.tm_mon, nowTime.tm_mday,
                            nowTime.tm_hour, nowTime.tm_min, nowTime.tm_sec)

    relDir= now.strftime("%Y%m%d")
    runCommand("mkdir -p %s" %  os.path.join(options.targetDir,relDir))
    relPath = os.path.join(relDir, "falcon_%s.txt" % now.strftime("%Y%m%d_%H%M%S") )
    fileTimeVal =  now.strftime("%Y%m%d%H%M%S") 
    outputFile = os.path.join(options.targetDir, relPath)
    if options.verbose:
	print >>sys.stderr, "writing output to ", outputFile
    out = open(outputFile, 'w')
    # output the lines of the file
    if options.simulate == True:
      now -= timedelta(minutes=options.before)
      print >>sys.stderr, "Writing Simulated data"
      # in simulate mode, use 'options.before' previous to current time, 
      # with a time different of 'delta' seconds per line/point
      text = response.read()
      lines = text.split('\n')
      out.write(lines[0])
      out.write('\n')  # terminate the line
      for l in lines[1:]:
	words = l.split(',')
#	print 'words =', words
	newTimeStr = now.strftime("%Y%m%dT%H%M%S")
#	print 'newTimeStr =',  newTimeStr
	try:
	  out.write('%s,%s,%s,%s,%s\n' % (words[0], newTimeStr, words[2],words[3], words[4]))
	except IndexError:
	  break
	now += timedelta(seconds=options.delta)
	
  
    else:
      out.write(response.read())
  
    out.close()
    conn.close()
 
    # update _latest_data_info
    cmd = "LdataWriter -dir " + options.targetDir \
                      + " -rpath " + relPath \
                      + " -ltime " + fileTimeVal \
                      + " -writer getFalconTracksByHttp.py" \
                      + " -dtype " + options.dataType
    runCommand(cmd)
    print >>sys.stderr, "fileTimeVal = ", fileTimeVal

        
    print "=========================================================================="
    print "END: getFalconTracksByHttp.py at " + str(datetime.datetime.now())
    print "=========================================================================="

    sys.exit(0)


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
    parser.add_option('--verbose',
                      dest='verbose', default='False',
                      action="store_true",
                      help='Set verbose debugging on')
    parser.add_option('--httpServer',
                      dest='httpServer',
                      default='hector.safire.fr',
                      help='Name of http server host')
    parser.add_option('--httpPort',
                      dest='httpPort',
                      default=8081,
                      help='port #')
    parser.add_option('--httpTimeout',
                      dest='httpTimeout',
                      default=40,
                      help='time out (secs)')
    parser.add_option('--trackTextFile',
                      dest='trackTextFile',
                      default='/track.txt',
                      help='Path of flight track in CSV text format ')
    defaultTargetDir = os.getenv("DATA_DIR") + "/raw/ac_posn/falcon"
    parser.add_option('--targetDir',
                      dest='targetDir',
                      default=defaultTargetDir,
                      help='Path of target directory')

    parser.add_option('--dataType',
                      dest='dataType',
                      default="raw",
                      help='Type of data for DataMapper')

    parser.add_option('--simulate',
                      dest='simulate',
                      default=False,
                      help='simulate live data')

    parser.add_option('--delta',
                      dest='delta',
                      default=5,
                      help='delta time for simulate option ')

    parser.add_option('--before',
                      dest='before',
                      default=240,
                      help='minutes before now to start flight')





    (options, args) = parser.parse_args()

    if (options.verbose == True):
        options.debug = True

    if (options.debug == True):
        print >>sys.stderr, "Options:"
        print >>sys.stderr, "  debug? ", options.debug
        print >>sys.stderr, "  httpServer: ", options.httpServer

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
