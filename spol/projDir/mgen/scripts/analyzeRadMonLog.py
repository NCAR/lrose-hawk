#!/usr/bin/env python

#===========================================================================
#
# Analyze a RadMon log for antenna speed etc
#
#===========================================================================

import os
import sys
import subprocess
from optparse import OptionParser
import time
import datetime
from datetime import date
from datetime import timedelta
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.mlab as mlab

class ray(object):
    
    def __init__(self, time, scanMode, volNum, tiltNum,
                 el, az, elRate, azRate):
        self.time = time
        self.scanMode = scanMode
        self.volNum = volNum
        self.tiltNum = tiltNum
        self.el = el
        self.az = az
        self.elRate = elRate
        self.azRate = azRate

    def __str__(self):
        return "ray: " + \
               "time:" + self.time.__str__() + "," + \
               "scanMode:" + self.scanMode + "," + \
               "volNum:" + self.volNum.__str__() + "," + \
               "tiltNum:" + self.tiltNum.__str__() + "," + \
               "el:" + self.el.__str__() + "," + \
               "az:" + self.az.__str__() + "," + \
               "elRate:" + self.elRate.__str__() + "," + \
               "azRate:" + self.azRate.__str__()

    def printArgs(self):
        print "ray:"
        print "  time: ", self.time
        print "  scanMode: ", self.scanMode
        print "  volNum: ", self.volNum
        print "  tiltNum: ", self.tiltNum
        print "  el: ", self.el
        print "  az: ", self.az
        print "  elRate: ", self.elRate
        print "  azRate: ", self.azRate
        
def main():

    global options
    global debug
    global logLines
    global rays

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
    parser.add_option('--logPath',
                      dest='logPath', default='/tmp/RadMon.log',
                      help='Path to log file')

    (options, args) = parser.parse_args()

    if (options.verbose == True):
        options.debug = True

    if (options.debug == True):
        print >>sys.stderr, "Running analyzeRadMonLog:"
        print >>sys.stderr, "  logPath: ", options.logPath

    # read in lines from log file

    readLogFile()

    if (options.verbose == True):
        for line in logLines:
            print >>sys.stderr, "Got line: ", line

    # load up rays

    loadRays()

    # plot the rays

    plotRays()

    sys.exit(0)

########################################################################
# Read in the log file

def readLogFile():

    global logLines
    logLines = []

    fp = open(options.logPath, 'r')
    text = fp.read()
    lines = text.splitlines()

    for line in lines:
        if ((line.find("SUR") >= 0) or (line.find("RHI") >= 0)):
            logLines.append(line)

########################################################################
# load rays from log file lines

def loadRays():

    global rays
    rays = []
    
    count = 0
    prevAz = 0.0
    prevEl = 0.0
    prevTime = datetime.datetime(1970, 1, 1, 0, 0, 0, 0)

    for line in logLines:

        toks = line.split()
        if (len(toks) < 11):
            continue
        scanMode = toks[0]
        volNum = int(toks[1])
        tiltNum = int(toks[2])
        fixedAngle = float(toks[3])
        if (scanMode == "SUR"):
            el = float(toks[4])
            az = float(toks[5])
        else:
            az = float(toks[4])
            el = float(toks[5])
        
        nGates = int(toks[6])
        gateSpacing = float(toks[7])
        PRF = float(toks[8])
        dateStr = toks[9]
        timeStr = toks[10]

        year = int(dateStr[0:4])
        month = int(dateStr[5:7])
        day = int(dateStr[8:10])
        hour = int(timeStr[0:2])
        minute = int(timeStr[3:5])
        second = int(timeStr[6:8])
        microsec = int(timeStr[9:15])

        btime = datetime.datetime(year, month, day,
                                  hour, minute, second,
                                  microsec)

        deltaAz = 0.0
        deltaEl = 0.0
        deltaTime = timedelta(0)
        deltaSecs = 0.0

        if (count > 0):
            deltaAz = az - prevAz
            if (deltaAz < -180):
                deltaAz = deltaAz + 360
            elif (deltaAz > 180):
                deltaAz = deltaAz - 360
            deltaEl = el - prevEl
            deltaTime = btime - prevTime
            deltaSecs = (deltaTime.days * 86400.0 +
                         deltaTime.seconds +
                         deltaTime.microseconds * 1.0e-6)

        prevEl = el
        prevAz = az
        prevTime = btime
        count = count + 1

        if (count == 1):
            continue

        if (deltaSecs == 0):
            azRate = 0.0
            elRate = 0.0
        else:
            azRate = deltaAz / deltaSecs
            elRate = deltaEl / deltaSecs

        thisRay = ray(btime, scanMode, volNum, tiltNum,
                      el, az, elRate, azRate)
        rays.append(thisRay)

        if (options.verbose == True):
            print >>sys.stderr, thisRay
            
########################################################################
# plot results

def plotRays():

    el = []
    az = []
    azRate = []

    prevAz = -9999
    for ray in rays:
        if (ray.scanMode == "SUR"):

            # avoid wrap at 360 - insert NaNs

            if (prevAz > -9990):
                deltaAz = ray.az - prevAz
                if (deltaAz < -180 or deltaAz > 180):
                    el.append(float('NaN'))
                    az.append(float('NaN'))
                    azRate.append(float('NaN'))
            prevAz = ray.az
                
            el.append(ray.el)
            az.append(ray.az)
            azRate.append(ray.azRate)

    fig = plt.figure()
    
    a = fig.add_subplot(3,1,1)
    a.set_title('Antenna position')
    a.plot(az, el, linewidth=1.0)
    a.grid(True)
    a.set_xlabel('Az (deg)')
    a.set_ylabel('El (deg)')

    b = fig.add_subplot(3,1,2)
    b.set_title('Antenna azimuth rate')
    b.plot(az, azRate, linewidth=1.0)
    b.grid(True)
    b.set_xlabel('Az (deg)')
    b.set_ylabel('AzRate (deg/s)')
    
    c = fig.add_subplot(3,1,3)
    c.set_title('Antenna azimuth rate - bounded')
    c.plot(az, azRate, linewidth=1.0)
    c.set_ybound(lower=9.0, upper=11.0)
    c.grid(True)
    c.set_xlabel('Az (deg)')
    c.set_ylabel('AzRate (deg/s)')
    
    plt.show()

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
