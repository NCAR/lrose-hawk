README FOR VAISALA/SIGMET RVP8 RDA SOFTWARE UPGRADE
===================================================

1. Make sure user 'operator' is set up properly
-----------------------------------------------

The rvp8 RDA software runs under user 'operator'.

The login shell must be 'ksh' - the Korn shell.

2. Download docs from Sigmet ftp site
-------------------------------------

  ftp://ftp.sigmet.com/outgoing/manuals/rvp8user/

The important docs are:

  2setup.pdf - general set up
  3install.pdf - installation
  4plots.pdf - plot to assist with setup

3. Download latest release from Sigmet ftp site
------------------------------------------------

For example:

  ftp://ftp.sigmet.com/outgoing/releases/8.12.3/RHEL5/rda/

Store on rvp8 under user 'operator':

  /home/operator/8.12.3

4. Save the old version
-----------------------

tar xvfz /home/operator/save/user_sigmet.20100330.tgz /usr/sigmet

5. Install latest version
--------------------------

  cd /home/operator/8.12.3
  chmod +x install
  su (become root)
  ./install

Choose:

  Upgdrade
  Manuals
  Headers
  Objects
  Source
  Verbose

The installation actually occurs in:

  /usr/sigmet

6. Make sure the Intel primitives library is installed
------------------------------------------------------

You will find the following in ~/shared_libs:

   libguide.so 
   libippcore.so
   libippsa6.so
   libippspx.so
   libipps.so
   libippst7.so
   libippsw7.so

These shared objects, or the latest versions of them, should be
copied to /usr/lib. Do this as root.

7. Stop rvp8 if running
-----------------------

  su
  /etc/init.d/rvp8 stop

or

  su

Find rvp8 process:

  ps -auxww | grep rvp8
  killproc ???? -TERM (where ???? is rvp8 process ID)
  rm -f /var/lock/subsys/rvp8

8. Copy the latest software to flash memory on the rvp8
-------------------------------------------------------

  cd /usr/sigmet/bin/rda

  rdaflash -program rvp8rx-0
  rdaflash -program rvp8tx-0
  rdaflash -program io62-0
  rdaflash -program io62cp-0

9. Run setup to make sure the configuration is correct
------------------------------------------------------

  cd /usr/sigmet/bin
  ./setup

10. Start the rvp8 process in the foreground, checking for errors
-----------------------------------------------------------------

  su
  cd /usr/sigmet/bin/rda
  ./rvp8

Check for errors.

You should get something like the following output:

  $ ./rvp8
      Sigmet - Part of Vaisala Group
  RVP8 Digital IF Signal Processor V12.3 IRIS-8.12.3
  --------------------------------------------------
  Initial startup at: 15:35:59 31 MAR 2010
  CPU-Type: Pentium(R) 4 Hyperthreaded
  IPP-Library: libippsw7.so v4.0 4.0.19.77
  Loading setup files...
  Using receiver mode 3 (Dual Pol on single IFD)
  Attaching to timeseries API...
  Starting IRIS antenna driver...

  Attaching to SIGMET PCI hardware...
    Found PCI Card RVP8/Rx - Rev.C:1  Serial:2569  Code:9  (/dev/rda/rvp8rx-0)
     \--> Remote IFD Assy  - Rev.G:1  Serial:2622  Code:6 
    Found PCI Card RVP8/Tx - Rev.D:1  Serial:2198  Code:15 (/dev/rda/rvp8tx-0)
    Found PCI Card I/O-62  - Rev.B:1  Serial:1767  Code:30 (/dev/rda/io62-0)
     \--> IO62CP Backpanel - Rev.A:1  Serial:1698  Code:4 

  Running RVP8/Rx diagnostics...
    PCI bus pattern mirror...
    Testing U10/U11 (4-MB) RAM...
    Testing U12/U13 (4-MB) RAM...
    PCI/DMA bus master transfers...
      (Raw: 130.4 MB/sec, Buffered: 126.5 MB/sec)
    Downlink local counter test...
    Downlink signal detect...
    System time clock monotonicity...
    Receiver status bits & switches...
      (Detected IFD Firmware Rev.6)
    Test word pattern from receiver...
    Test byte pattern from receiver...
    Round trip delay and jitter...
      (Delay = 0.486 usec, Jitter = 0.000 usec)
    Range Mask and (I,Q) data logger...
    FIR filter (12 DSP blocks)...
    (I,Q) floating normalization...
    CAT-5E link bit error check..  .

  Running RVP8/Tx diagnostics...
    PCI bus pattern mirror...
    Testing U10/U11 (2MB) RAM...

  Running I/O-62 diagnostics...
    PCI bus pattern mirror...

  Configuring Softplane...
    Assuming PCI backplane order:  1:Rx-2569  2:Tx-2198  3:Io-1767
    FlexCircuit ribbons between PCI cards are all working properly
    I/O-62-0 is 'IO62CP' with 32 control and 32 status lines (5 active pairs)

  Forking parallel compute process(es)...
    RVP8Proc-0 - PID:10595   Priority:10  Policy:RealTimeRR
    RVP8Proc-1 - PID:10596   Priority:10  Policy:RealTimeRR

  Shared library build dates:
    RVP8/Main/Core: Fri Jun 26 14:02:41 EDT 2009
    RVP8/Main/Open: Fri Jun 26 14:02:45 EDT 2009
    RVP8/Main/Site: Fri Jun 26 14:02:42 EDT 2009
    RVPX/Proc/Core: Fri Jun 26 14:02:46 EDT 2009
    RVPX/Proc/Open: Fri Jun 26 14:02:51 EDT 2009
    RVPX/Proc/Site: Fri Jun 26 14:02:47 EDT 2009

  Creating RVP8/Main realtime threads... (7 created)
    Chat/Plot  - PID:10594   Priority:10  Policy:RealTimeRR
    Burst/AFC  - PID:10594   Priority:10  Policy:RealTimeRR
     Watchdog  - PID:10594   Priority:10  Policy:RealTimeRR
     HostCmds  - PID:10594   Priority:11  Policy:RealTimeRR
      IQ-Data  - PID:10594   Priority:11  Policy:RealTimeRR
      RT-Ctrl  - PID:10594   Priority:12  Policy:RealTimeRR
       Angles  - PID:10594   Priority:12  Policy:RealTimeRR

  Initializations complete - The RVP8 is now operational.

11. Start the rvp8 process as a daemon, in the background.
----------------------------------------------------------

  su
  cd /usr/sigmet/bin/rda
  ./rvp8 -daemon

12. Run dspx to check the configuration
---------------------------------------

  cd /usr/sigmet/bin
  ./dspx

  Hit ESC to enter setup mode.

  Then enter ?? to see all settings.
  Enter ? for help. You can do the following:

  Command List:
    F: Use Factory Defaults
    S: Save Current Settings
    R: Restore Saved Settings
    M: Modify/View Current Settings
        Mb - Burst Pulse and AFC
        Mc - Overall Configuration
        Mf - Clutter Filters
        Mp - Processing Options
        Mt<n> - Trigger/Timing <for PW n>
        Mz - Transmissions and Modulations
        M+ - Debug Options
    P: Plot with Virtual Oscilloscope
        Pa - Tx Pulse Ambiguity Diagram
        Pb - Burst Pulse Timing
        Ps - Burst Spectra and AFC
        Pr - Receiver Waveforms
        P+ - Visual Test Pattern
    V: View Card and System Status
        Vz - Like 'V', but resets internal states
        Vp - Show Processing and Threshold values
    ?: Print all Menu Commands (this list)
        ?? - Print all Current Setup Settings
    @: Display/Change the Current Major Mode
    ~: Swap Burst/IF Inputs (~i swaps Pri/Sec IF)
    Q: Quit

  Hit Q and then CTRL-C to exit.

13. Install rvp8 startup in /etc/init.d
---------------------------------------

The startup / shutdown scripts config for the rvp8 is found in:

  /usr/sigmet/config/rc.d

Add rvp8 to init.d by running:

 chkconfig --add rvp8



