#!/usr/bin/env python

#===========================================================================
#
# Analyze monitoring logs for the Sband
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

class entry(object):
    
    def __init__(self, time,
                 powerHc, powerVc,
                 powerHx, powerVx):
        self.time = time
        self.powerHc = powerHc
        self.powerVc = powerVc
        self.powerHx = powerHx
        self.powerVx = powerVx

        def __str__(self):
            return "entry: " + \
                   "time:" + self.time.__str__() + "," + \
                   "powerHc:" + self.powerHc + "," + \
                   "powerVc:" + self.powerVc.__str__() + "," + \
                   "powerHx:" + self.powerHx.__str__() + "," + \
                   "powerVx:" + self.powerVx.__str__()

    def printArgs(self):
        print "entry:"
        print "  time: ", self.time
        print "  powerHc: ", self.powerHc
        print "  powerVc: ", self.powerVc
        print "  powerHx: ", self.powerHx
        print "  powerVx: ", self.powerVx
        
def main():

    global options
    global debug
    global commentLines
    global logLines
    global entries
    global dailyMeans

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
        print >>sys.stderr, "Running analyzeSbandMonitorLogs:"
        print >>sys.stderr, "  logPath: ", options.logPath

    # read in lines from log file

    readLogFile()

    if (options.debug == True):
        for line in commentLines:
            print >>sys.stderr, "Got comment line: ", line

    if (options.verbose == True):
        for line in logLines:
            print >>sys.stderr, "Got log line: ", line

    # find columns for test pulse powers

    (colTestPulseHc, colTestPulseVc, colTestPulseHx, colTestPulseVx) = \
                     findTestPulseColumns()

    # load up test pulse entries

    loadEntries(colTestPulseHc, colTestPulseVc,
                colTestPulseHx, colTestPulseVx)

    # compute daily means

    computeDailyMeans()

    # plot the entries

    plotEntries()

    sys.exit(0)

########################################################################
# Read in the log file

def readLogFile():

    global commentLines
    commentLines = []

    global logLines
    logLines = []

    fp = open(options.logPath, 'r')
    text = fp.read()
    lines = text.splitlines()

    for line in lines:
        if (line.find("#") == 0):
            commentLines.append(line)
        else:
            logLines.append(line)

########################################################################
# find columns for test pulse powers

def findTestPulseColumns():

    colTestPulseHc = findColumn("TestPulsePowerDbHc")
    colTestPulseVc = findColumn("TestPulsePowerDbVc")
    colTestPulseHx = findColumn("TestPulsePowerDbHx")
    colTestPulseVx = findColumn("TestPulsePowerDbVx")

    if (options.debug == True):
        print >>sys.stderr, "  colTestPulseHc: ", colTestPulseHc
        print >>sys.stderr, "  colTestPulseVc: ", colTestPulseVc
        print >>sys.stderr, "  colTestPulseHx: ", colTestPulseHx
        print >>sys.stderr, "  colTestPulseVx: ", colTestPulseVx

    return (colTestPulseHc, colTestPulseVc, colTestPulseHx, colTestPulseVx)

########################################################################
# find column for a given tag

def findColumn(tag):

    for line in commentLines:
        if (line.find(tag) > 0):
            colStrStart = line.find("col")
            if (colStrStart >= 0):
                numStart = colStrStart + 4
                numEnd = line.find(":", numStart)
                numStr = line[numStart:numEnd]
                return int(numStr)

    return -1

########################################################################
# load entries from log file lines

def loadEntries(colTestPulseHc, colTestPulseVc, colTestPulseHx, colTestPulseVx):

    global entries
    entries = []
    
    count = 0
    prevAz = 0.0
    prevEl = 0.0
    prevTime = datetime.datetime(1970, 1, 1, 0, 0, 0, 0)

    for line in logLines:

        toks = line.split(',')
        if (len(toks) < colTestPulseVx + 1):
            continue

        try:
            powerHc = float(toks[colTestPulseHc])
            powerVc = float(toks[colTestPulseVc])
            powerHx = float(toks[colTestPulseHx])
            powerVx = float(toks[colTestPulseVx])
        except ValueError:
            continue

        if (powerHc - powerVc) > 4.0:
            continue
        if (powerHc - powerVc) < 3.5:
            continue
        if (powerHc - powerVx) > 4.0:
            continue
        if (powerHc - powerVx) < 3.5:
            continue
        
        powerHc = float(toks[colTestPulseHc])
        powerVc = float(toks[colTestPulseVc])
        powerHx = float(toks[colTestPulseHx])
        powerVx = float(toks[colTestPulseVx])
        
        year = int(toks[0])
        month = int(toks[1])
        day = int(toks[2])
        hour = int(toks[3])
        minute = int(toks[4])
        second = int(toks[5])
        
        etime = datetime.datetime(year, month, day,
                                  hour, minute, second)
        
        thisEntry = entry(etime, powerHc, powerVc, powerHx, powerVx)
        entries.append(thisEntry)
        if (options.verbose == True):
            thisEntry.printArgs()
            
########################################################################
# compute daily means

def computeDailyMeans():

    global dailyMeans
    dailyMeans = []

    prevTime = entries[0].time
    sumHc = 0.0
    sumVc = 0.0
    sumHx = 0.0
    sumVx = 0.0
    count = 0.0
    
    for thisEntry in entries:
        thisTime = thisEntry.time
        if (thisTime.day == prevTime.day):
            sumHc = sumHc + thisEntry.powerHc
            sumVc = sumVc + thisEntry.powerVc
            sumHx = sumHx + thisEntry.powerHx
            sumVx = sumVx + thisEntry.powerVx
            count = count + 1.0
        else:
            meanTime = datetime.datetime(prevTime.year,
                                         prevTime.month,
                                         prevTime.day,
                                         12, 0, 0)
            meanEntry = entry(meanTime,
                              sumHc / count,
                              sumVc / count,
                              sumHx / count,
                              sumVx / count)
            dailyMeans.append(meanEntry)
            prevTime = thisTime
            sumHc = 0.0
            sumVc = 0.0
            sumHx = 0.0
            sumVx = 0.0
            count = 0.0

    if (count > 0):
        meanTime = datetime.datetime(prevTime.year,
                                     prevTime.month,
                                     prevTime.day,
                                     12, 0, 0)
        meanEntry = entry(meanTime,
                          sumHc / count,
                          sumVc / count,
                          sumHx / count,
                          sumVx / count)
        dailyMeans.append(meanEntry)

########################################################################
# plot results

def plotEntries():

    times = []
    hcMinusVc = []

    for entry in entries:
        times.append(entry.time)
        hcMinusVc.append(entry.powerHc - entry.powerVc)

    fig = plt.figure()
    
    a = fig.add_subplot(4,1,1)
    a.set_title('Hc minus Vc - each minute')
    a.plot(times, hcMinusVc, linewidth=1.0)
    a.grid(True)
#    a.set_xlabel('Time')
    a.set_ylabel('Hc-Vc')
    a.set_ybound(lower=3.5, upper=4.0)

    times = []
    hcMinusVc = []

    for entry in dailyMeans:
        times.append(entry.time)
        hcMinusVc.append(entry.powerHc - entry.powerVc)

    b = fig.add_subplot(4,1,2)
    b.set_title('Hc minus Vc - daily means')
    b.plot(times, hcMinusVc, linewidth=1.0)
    b.grid(True)
#    b.set_xlabel('Time')
    b.set_ylabel('Hc-Vc')
    b.set_ybound(lower=3.5, upper=4.0)

    times = []
    hcMinusVx = []

    for entry in entries:
        times.append(entry.time)
        hcMinusVx.append(entry.powerHc - entry.powerVx)

    c = fig.add_subplot(4,1,3)
    c.set_title('Hc minus Vx - each minute')
    c.plot(times, hcMinusVx, linewidth=1.0)
    c.grid(True)
#    c.set_xlabel('Time')
    c.set_ylabel('Hc-Vx')
    c.set_ybound(lower=3.5, upper=4.0)

    times = []
    hcMinusVx = []

    for entry in dailyMeans:
        times.append(entry.time)
        hcMinusVx.append(entry.powerHc - entry.powerVx)

    d = fig.add_subplot(4,1,4)
    d.set_title('Hc minus Vx - daily means')
    d.plot(times, hcMinusVx, linewidth=1.0)
    d.grid(True)
#    d.set_xlabel('Time')
    d.set_ylabel('Hc-Vx')
    d.set_ybound(lower=3.5, upper=4.0)

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
