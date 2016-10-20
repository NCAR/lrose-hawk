#!/usr/bin/env python

# ========================================================================== #
#
# Configure the host for a given role
#
# ========================================================================== #

import os
import sys
from optparse import OptionParser
import datetime
import subprocess
import string

def main():

    global options

    homeDir = os.environ['HOME']
    projDir = os.path.join(homeDir, 'projDir')
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

    # save the host type to ~/.host_type

    hostTypeFile = open(hostTypePath, "w")
    hostTypeFile.write(hostType + '\n')
    hostTypeFile.close()

    # banner

    print " "
    print "*********************************************************************"
    print
    print "  configure_host for SPOL HAWK"
    print
    print "  runtime: " + str(datetime.datetime.now())
    print
    print "  host type: ", hostType
    print
    print "*********************************************************************"
    print " "

    # make links to the dotfiles in git projDir
    
    os.chdir(homeDir)
    for rootName in ['cshrc', 'bashrc', 'emacs',
                     'Xdefaults', 'sigmet_env', 'valgrindrc' ]:
        dotName = '.' + rootName
        removeSymlink(homeDir, dotName)
        sourceDir = os.path.join(gitSystemDir, 'dotfiles')
        sourcePath = os.path.join(sourceDir, rootName)
        cmd = "ln -s " + sourcePath + " " + dotName
        runCommand(cmd)

    # make link to projDir

    removeSymlink(homeDir, 'projDir')
    os.chdir(homeDir)
    cmd = "ln -s " + gitProjDir
    runCommand(cmd)
    
    ############################################
    # data dir - specific to the host type
    # populate installed data dir /data/spol
    
    templateDataDir = os.path.join(options.hawkGitDir, 'data_dirs')
    templateDataDir = os.path.join(templateDataDir, 'data.' + hostType)
    installDataDir = '/data/spol/data.' + hostType

    # rync template dir into data area

    os.chdir(projDir)
    cmd = "rsync -av " + templateDataDir + " /data/spol"
    runCommand(cmd)

    # create symlink to data

    removeSymlink(projDir, 'data')
    cmd = "ln -s " + installDataDir + " data"
    runCommand(cmd)

    # create symlink to logs

    removeSymlink(projDir, 'logs')
    cmd = "ln -s data/logs"
    runCommand(cmd)

    # create symlink to template

    removeSymlink(projDir, 'template')
    cmd = "ln -s " + templateDataDir + " template"
    runCommand(cmd)

    # create symlinks from data tree back into the template

    debugStr = ""
    if (options.debug):
        debugStr = " --debug"
    cmd = "createParamLinks.py --templateDir template --installDir data" + debugStr
    runCommand(cmd)

    # done

    sys.exit(0)
    
########################################################################
# Remove a symbolic link
# Exit on error

def removeSymlink(dir, linkName):

    os.chdir(dir)

    # remove if exists
    if (os.path.islink(linkName)):
        os.unlink(linkName)
        return

    if (os.path.exists(linkName)):
        # link name exists but is not a link
        print >>sys.stderr, "ERROR - trying to remove symbolic link"
        print >>sys.stderr, "  dir: ", dir
        print >>sys.stderr, "  linkName: ", linkName
        print >>sys.stderr, "This is NOT A LINK"
        sys.exit(1)

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
            if (options.verbose == True):
                print >>sys.stderr, "Child returned code: ", retcode
    except OSError, e:
        print >>sys.stderr, "Execution failed:", e

########################################################################
# Run - entry point

if __name__ == "__main__":
   main()
