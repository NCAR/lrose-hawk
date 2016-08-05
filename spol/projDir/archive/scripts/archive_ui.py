#!/usr/bin/python

#import TkInter as tk
import Tix
from Tkconstants import *
import subprocess
import time
import glob
import sys

class DriveStatStringVars:
    """ store sets of StringVars used to update drive info """
    def __init__(self):
	self.mount = []
	self.label = []
	self.size = []
	self.used = []
	self.avail = []
	self.percent = []

class StringVarLabel:
    """ create a Label and the associated StringVar, and grid the label"""
    def __init__(self,  row, column, rowspan=1, colspan=1, default='------'):
	self.svar = Tix.Tkinter.StringVar()
	self.svar.set(default)
	label = Tix.Tkinter.Label(textvariable = self.svar)
	label.grid(row=row,column=column,rowspan = rowspan, columnspan = colspan)
    
    def stringVar(self):
	return self.svar
    


class App:
    def __init__(self, root, minutes_since_midnight):
	self._driveList = []
	self._mountedDriveList = []
	self._waitmsg = '|||||'
	self._root = root
	self._min_minutes_since_midnight = minutes_since_midnight
	row = 0
	w = Tix.Tkinter.Label(root, text="Archive Control 0.4")
        w.grid(row=row,columnspan=8)
	row +=1

	# find the list of potentially mounted drives
	fstab = open('/etc/fstab', 'r')
	lines = fstab.readlines()
	print 'lines = ', lines
	fstab.close()
	for l in lines:
	    words= l.split()
	    if (len(words) ==6) and (words[1].find('/usb/SPOL_') != -1):
		    self._driveList.append(words[1])

	print 'self._driveList = ', self._driveList
	
	StringVarLabel(row,0, 1, 1).stringVar().set('Mount Point')
	StringVarLabel(row,1, 1, 1).stringVar().set('Drive Label')
	StringVarLabel(row,2 , 1, 1).stringVar().set('Size')
	StringVarLabel(row,3 ,  1, 1).stringVar().set('Used')
	StringVarLabel(row,4,  1, 1).stringVar().set('Available')
	StringVarLabel(row,5 , 1, 1).stringVar().set('Percent Used')
	row +=1

	self._stringVars = DriveStatStringVars()
	for d in self._driveList:

	    self._stringVars.mount.append(StringVarLabel(row, 0).stringVar())
	    self._stringVars.label.append(StringVarLabel(row, 1).stringVar())
	    self._stringVars.size.append(StringVarLabel(row, 2).stringVar())
	    self._stringVars.used.append(StringVarLabel(row, 3).stringVar())
	    self._stringVars.avail.append(StringVarLabel(row, 4).stringVar())
	    self._stringVars.percent.append(StringVarLabel(row, 5).stringVar())
	    row +=1
	

	self._buttonLabel = Tix.Tkinter.StringVar()
	self._buttonLabel.set("Click to Unmount Drives")
	self._button=  Tix.Tkinter.Button(root, textvariable= self._buttonLabel,
		command=self.try_unmount)
	self._button['state'] = DISABLED
	self._button.grid(row=row,columnspan=8)
	row +=1

	# create a variable we can update to change the message text
	self._statusMsg = StringVarLabel(row, 0, 2, 8).stringVar()

	self.update_drive_info()  # update list of mounted drives before trying to mount

	self.try_mount()

	self._root.after(10*1000, self.update_drive_info)

	self.check_time()

    def check_time(self):
	"""
	wait until self._minutes_since_midnight before
	allowing unmounting drives
        """
	# get current time
	now_tuple = time.gmtime(time.time())
#	print 'now = ', now_tuple
	cur_minutes = now_tuple[3]*60 + now_tuple[4]
#	print 'cur_minutes = ', cur_minutes, \
# "self._min_minutes_since_midnight", self._min_minutes_since_midnight
	if cur_minutes > self._min_minutes_since_midnight:
	    self._button['state'] = ACTIVE
	    self._statusMsg.set("---------------------------")
	else:
	    self._button['state'] = DISABLED
	    hour = self._min_minutes_since_midnight / 60
	    min = self._min_minutes_since_midnight - (hour * 60)
	    self._statusMsg.set("Please wait until after  %02d:%02dZ to change tapes" 
		% (hour, min))

	self._root.after(10*1000, self.check_time)
	    
    
	

    def _do_unmount_drive(self, driveName):
	print 'do_unmount called : %s' % driveName
	cmd = ('umount', driveName)
	rc = subprocess.call(cmd)
	if rc == 0: 
	    self._mountedDriveList.remove(driveName)
	    print 'do_unmount - unmounted ', driveName
	    val= True
	else:
	    print 'do_unmount - failed ', driveName
	    val = False
	print '_do_unmount : drive %s mounted = %s' % (driveName, 
	    repr(driveName in self._mountedDriveList))
	return val
	

    def try_unmount(self):
	self._statusMsg.set( 'trying to unmount drives - please wait' )
	self._buttonLabel.set('%s  Please WAIT  %s ' % (self._waitmsg, self._waitmsg))
	self._root.update()
	if self._waitmsg == '|||||':
	    self._waitmsg = '-----'
	else:
	    self._waitmsg = '|||||'
	self._button['state'] = DISABLED
	self._root.update()
	
	stillMounted = 0
	for d in self._driveList:
	    if d in self._mountedDriveList:
		if not self._do_unmount_drive(d):
		    stillMounted +=1

        if stillMounted: 
	    self._root.after(10*1000, self.try_unmount)
	    return
	    
	# unmount worked -change the button action, tell the user
	self._button['command'] = self.try_mount
	self._root.update()
	self._statusMsg.set( 'drives are unmounted ' )
	self._buttonLabel.set('Click after changing drives')
	self._button['state'] = ACTIVE
	self._root.update()
	self.update_drive_info()

    def _do_mount_drive(self, driveName):
	print 'do_mount called : %s' % driveName
	cmd = ('mount', driveName)
	rc = subprocess.call(cmd)
	if rc == 0: 
	    self._mountedDriveList.append(driveName)
	    print 'do_mount - mounted ', driveName
            return True
	else:
	    print 'do_mount - failed ', driveName
	    self._statusMsg.set('Unable to Mount - Please check cables! ')
	    self._root.update()
            return False

    def try_mount(self):
	self._statusMsg.set('Please wait while I mount the drives')
	self._button['state'] = DISABLED
	self._root.update()

	notMounted = 0
	for d in self._driveList:
	    if d not in self._mountedDriveList:
		if not self._do_mount_drive(d):
		    notMounted +=1

        if notMounted: 
	    self._root.after(10*1000, self.try_mount)
	    return
	self._statusMsg.set( 'drives are Mounted ' )
	self._button['state'] = ACTIVE
	self._buttonLabel.set("Click to Unmount Drives")
	self._statusMsg.set("---------------------------")
	self._button['command'] = self.try_unmount
	self._root.update()
	self.update_drive_info()

    def update_drive_info(self):

	i = 0
	for d in self._driveList:
	    if d not in self._mountedDriveList:
		self._stringVars.label[i].set('-----')
		self._stringVars.size[i].set('-----')
		self._stringVars.used[i].set('-----')
		self._stringVars.avail[i].set('-----')
		self._stringVars.percent[i].set('------')
	    i +=1
	self._root.update()

	deviceTable = {}
	labelTable = {}
	spaceUsedTable = {}
	spaceAvailTable = {}
	spaceTotalTable = {}
	percentUsed = {}

	# run df

	pipe = subprocess.Popen('df --block-size=1G', shell=True,
				stdout=subprocess.PIPE).stdout
	lines = pipe.readlines()
	pipe.close()

	# load up drive list and associated tables

	self._mountedDriveList = []
	for line in lines:
	    tokens = line.split()
	    if (tokens[0].find('/dev') >= 0):
		partition = tokens[5]
		if (partition.find('SPOL_') >= 0):
		    self._mountedDriveList.append(partition)
		    deviceName = tokens[0]
		    total = tokens[1]
		    used = tokens[2]
		    avail = tokens[3]
		    deviceTable[partition] = deviceName
		    spaceUsedTable[partition] = used
		    spaceAvailTable[partition] = avail
		    spaceTotalTable[partition] = total
		    percentUsed[partition] = (float(used)/float(total))*100.0

	# sort drive list

	self._mountedDriveList.sort()

	print "driveList: ", self._driveList

	# run e2label to get volume label

	for drive in self._mountedDriveList:
	    deviceName = deviceTable[drive]
	    e2labelCmd = 'e2label ' + deviceName
	    pipe = subprocess.Popen(e2labelCmd, shell=True,
				    stdout=subprocess.PIPE).stdout
	    tokens = pipe.readlines()
            if (len(tokens) == 0):
                labelTable[drive] = "unknown"
                print >>sys.stderr, "ERROR: update_drive_info()"
                print >>sys.stderr, "  Cannot run e2label"
            else:
                driveLabel = tokens[0].rstrip()
                labelTable[drive] = driveLabel
            pipe.close()

	print self._mountedDriveList
	i = 0
	for d in self._mountedDriveList:
	    self._stringVars.mount[i].set(d)
	    self._stringVars.label[i].set(labelTable[d])
	    self._stringVars.size[i].set(spaceTotalTable[d])
	    self._stringVars.used[i].set(spaceUsedTable[d])
	    self._stringVars.avail[i].set(spaceAvailTable[d])
	    self._stringVars.percent[i].set('%02.0f' % percentUsed[d])
	    i +=1

	self._root.update()


if __name__ == '__main__':

    root=Tix.Tk()
    root.tk.eval('package require Tix')

    app= App(root, 2*60)  # 02:00Z
    root.mainloop()
