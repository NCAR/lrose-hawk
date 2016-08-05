#!/usr/bin/env python

# ========================================================================== #
#
# Check the archive disks for space
#
# ========================================================================== #

import os
import sys
import subprocess
from optparse import OptionParser
#from Tkinter import Tk, Toplevel, mainloop
#from Tkinter import Frame, Label, Button
#from Tkinter import GROOVE

def main():

    global options
    global debug
    global driveList
    global deviceTable
    global labelTable
    global spaceUsedTable
    global spaceAvailTable
    global spaceTotalTable

    # parse the command line

    usage = "usage: %prog [options]"
    parser = OptionParser(usage)
    parser.add_option('--debug',
                      dest='debug', default='False',
                      action="store_true",
                      help='Set debugging on')
    parser.add_option('--minSpace',
                      dest='minSpace', default='200',
                      help='Min allowable space in GigaBytes')
    
    (options, args) = parser.parse_args()

    if (options.debug == True):
        print >>sys.stderr, "Options:"
        print >>sys.stderr, "  Debug: ", options.debug
        print >>sys.stderr, "  minSpace (Gbytes): ", options.minSpace
        
    # compile the list of archive drives, including their sizes
    # and available space

    compileDriveList()

    if (options.debug == True):
        print >>sys.stderr, "  archive drive list: ", driveList

    # perform the archival, to each drive

    iret = 0
    for drive in driveList:
        avail = spaceAvailTable[drive]
        label = labelTable[drive]
        print "Drive %s has space %s GBytes" % (label, avail)
        if (int(avail) < int(options.minSpace)):
            print "WARNING!! drive low on space, min is: ", options.minSpace, " GBytes"
            iret = 1

    sys.exit(iret)

#    root = Tk()
#    root.title("Archive drive space check")
#    root.geometry('+300+300')
#    f = Frame(root, width=300, height=150)
#    xf = Frame(f, relief=GROOVE, borderwidth=2)
#    Label(text="This is a test").pack(pady=10)
#    root.mainloop()

#    for key in sorted(os.environ.iterkeys()):
#        variable = key
#        value = os.environ[key]
#        print "Var %s has value %s" % (variable, value)


########################################################################
# Get the list of drives and available space

def compileDriveList():

    global driveList
    global deviceTable
    global labelTable
    global spaceUsedTable
    global spaceAvailTable
    global spaceTotalTable

    deviceTable = {}
    labelTable = {}
    spaceUsedTable = {}
    spaceAvailTable = {}
    spaceTotalTable = {}

    # run df
    
    pipe = subprocess.Popen('df --block-size=1G', shell=True,
                            stdout=subprocess.PIPE).stdout
    lines = pipe.readlines()
    
    # load up drive list and associated tables
    
    driveList = []
    for line in lines:
        tokens = line.split()
        if (tokens[0].find('/dev') >= 0):
            partition = tokens[5]
            if (partition.find('SPOL_') >= 0):
                driveList.append(partition)
                deviceName = tokens[0]
                total = tokens[1]
                used = tokens[2]
                avail = tokens[3]
                deviceTable[partition] = deviceName
                spaceUsedTable[partition] = used
                spaceAvailTable[partition] = avail
                spaceTotalTable[partition] = total

    # sort drive list
    
    driveList.sort()

    print "driveList: ", driveList
    
    # run e2label to get volume label
    
    for drive in driveList:
        deviceName = deviceTable[drive]
        e2labelCmd = 'e2label ' + deviceName
        pipe = subprocess.Popen(e2labelCmd, shell=True,
                                stdout=subprocess.PIPE).stdout
        tokens = pipe.readlines()
        driveLabel = tokens[0].rstrip()
        labelTable[drive] = driveLabel

########################################################################
# Run - entry point

if __name__ == "__main__":
   main()
