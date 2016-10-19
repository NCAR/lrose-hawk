#!/usr/bin/env python

# ========================================================================== #
#
# Configure the host for a given role
#
# ========================================================================== #

import os
import sys
from optparse import OptionParser
import subprocess
import string

def main():

    global options
    homeDir = os.environ['HOME']
    # projDir = os.environ['PROJ_DIR']

    defaultHawkGitDir = os.path.join(homeDir, "git/lrose-hawk/spol")

    # parse the command line

    usage = "usage: %prog [options]"
    parser = OptionParser(usage)
    parser.add_option('--debug',
                      dest='debug', default=False,
                      action="store_true",
                      help='Set debugging on')
    parser.add_option('--verbose',
                      dest='verbose', default=False,
                      action="store_true",
                      help='Set verbose debugging on')
    parser.add_option('--hawkGitDir',
                      dest='hawkGitDir', default=defaultHawkGitDir,
                      help='Path of hawk directory in git')
    (options, args) = parser.parse_args()
    
    if (options.verbose):
        options.debug = True

    # compute paths

    gitProjDir = os.path.join(options.hawkGitDir, 'projDir')
    gitSystemDir = os.path.join(gitProjDir, 'system')
    
    # debug print

    if (options.debug):
        print >>sys.stderr, "Running script: ", os.path.basename(__file__)
        print >>sys.stderr, "  Options:"
        print >>sys.stderr, "    Debug: ", options.debug
        print >>sys.stderr, "    Verbose: ", options.verbose
        print >>sys.stderr, "    hawkGitDir: ", options.hawkGitDir
        print >>sys.stderr, "    gitProjDir: ", gitProjDir
        print >>sys.stderr, "    gitSystemDir: ", gitSystemDir

    # read current host type if previously set

    installedHostType = 'display'
    hostTypePath = os.path.join(homeDir, '.host_type')
    if (os.path.exists(hostTypePath)):
        hostTypeFile = open(hostTypePath, 'r')
        installedHostType = hostTypeFile.read()
        installedHostType = installedHostType.strip(string.whitespace)
    if (options.debug):
        print >>sys.stderr, "    installedHostType: ", installedHostType

    # get the host type interactively

    hostTypes = [ 'mgen', 'pgen', 'control', 'rvp8', 
                  'kadrx', 'spoldrx', 'dmgt', 'display' ]

    print "Choose host type from the following list"
    print "       or hit enter to use host type shown:"
    for hostType in hostTypes:
        print "     ", hostType
    hostType = raw_input('    ............. (' + installedHostType + ')? ')
    if (len(hostType) < 4):
        hostType = installedHostType
    else:
        typeIsValid = False
        for htype in hostTypes:
            if (hostType == htype):
                typeIsValid = True
        if (typeIsValid != True):
            print >>sys.stderr, "ERROR - invalid host type: ", hostType
            sys.exit(1)

    print "Setting host type to: ", hostType

    # save the host type to ~/.host_type

    hostTypeFile = open(hostTypePath, "w")
    hostTypeFile.write(hostType + '\n')
    hostTypeFile.close()

    sys.exit(0)

    # make the install dir

    try:
        os.makedirs(options.installDir)
    except OSError as exc:
        if (options.debug):
            print >>sys.stderr, "WARNING: trying to create install dir"
            print >>sys.stderr, "  ", exc

    # Walk the template directory tree

    for dirPath, subDirList, fileList in os.walk(options.templateDir):
        for fileName in fileList:
            if (fileName[0] == '_'):
                handleParamFile(dirPath, fileName)

    sys.exit(0)

########################################################################
# Handle a parameter file entry

def handleParamFile(dirPath, paramFileName):

    if (options.debug):
        print >>sys.stderr, "Handling param file, dir, paramFile: ", dirPath, ", ", paramFileName

    # compute sub dir

    subDir = dirPath[len(options.templateDir):]

    # compute install sub dir

    installSubDir = options.installDir + subDir

    if (options.debug):
        print >>sys.stderr, "subDir: ", subDir
        print >>sys.stderr, "installSubDir: ", installSubDir

    # make the install sub dir and go there

    try:
        os.makedirs(installSubDir)
    except OSError as exc:
        pass

    os.chdir(installSubDir)

    # remove the link if it exists

    if (os.path.exists(paramFileName)):
        os.remove(paramFileName)

    # create the link

    paramFilePath = os.path.join(options.templateDir + subDir, paramFileName)
    cmd = "ln -s " + paramFilePath
    runCommand(cmd)

    return

########################################################################
# Run a command in a shell, wait for it to complete

def runCommand(cmd):

    if (options.verbose == True):
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
