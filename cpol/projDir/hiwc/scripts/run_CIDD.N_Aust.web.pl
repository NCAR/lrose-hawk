#! /usr/bin/perl

$debug = 1;
$verbose = 1;
$ProjDir=$ENV{'PROJ_DIR'};
($prog = $0) =~ s|.*/||;

if ($debug == 1) {
  print(STDERR "==== LdataWatcher script - $prog ====\n");
  print(STDERR "====   Running CIDD to generate images from the merged data ====\n");
}

if ($verbose == 1) {
  print(STDERR "Script name: $prog\n");
  $count = 0;
  foreach $arg (@ARGV) {
    print(STDERR "  arg $count: $arg\n");
    $count++;
  }
}

# Ensure virtual X server is running and set display accordingly. 
$cmd = "$ProjDir/system/scripts/start_Xvfb";
system($cmd);
$cmd = "DISPLAY=':1.0'";
system($cmd);
$cmd = "export DISPLAY";
print(STDERR "  cmd= $cmd\n");
system($cmd);
#echo $DISPLAY;

# run CIDD unmapped to produce web output

$cmd = "CIDD -p $ProjDir/radars/N_Aust/params/CIDD.N_Aust.web -u &";
system($cmd);

exit(0);






