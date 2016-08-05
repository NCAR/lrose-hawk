debug_log="/omd/sites/prod/var/log/check_mk_debug.log"

# The TX_Filament_PS_Voltage_Fault seems to be a false alarm - 2011/9/29, JVA
ignored_services = [
 (ALL_HOSTS, ["NFS.*/net.*", "NFS.*/scr.*","CUPS.*","Mount options of.*", "Postfix.*",
"TX_Filament_PS_Voltage_Fault" ])
]

# Put your host names here
all_hosts = [ 
'eng|display', 
'sci1|display',
'sci2|display',
'mgen|server',
'pgen1|server', 
'pgen2|server', 
'rvp8|server',
'control|server',
'kadrx|server',
'nomad|server',
'uwraid|server',
'sixnet1|utility',
# 's2d|utility',
#'trigger|utility',
'spol-dm|utility',
'spol-dm2|utility',
]

host_groups = [
 # Put all hosts with the tag 'server' into the host group server
 ( 'server',      ['server'], ALL_HOSTS ),
 ( 'display',      ['display'], ALL_HOSTS ),
 ( 'utility',      ['utility'], ALL_HOSTS ),
]

define_servicegroups= True
define_hostgroups=True

service_groups = [
  # All services beginning with "fs" on hosts with the tag "server"
  # go into the service group "serverfs".
  ( 'server_fs',  ['server'], ALL_HOSTS, ['fs'] ),
  ( 'display_fs',  ['display'], ALL_HOSTS, ['fs'] ),
  ( 'hawk_procs',  ['server'], ALL_HOSTS, ['HP_'] ),
  ( 'hawk_sum_procs',  ['server'], ALL_HOSTS, ['HawkSummary_Processes'] ),
  ( 'hawk_data',  ['server'], ALL_HOSTS, ['HD_'] ),
  ( 'hawk_sum_data',  ['server'], ALL_HOSTS, ['HawkSummary_Data'] ),
  ( 'Antenna',  ['utility'], ALL_HOSTS, ['ANT_'] ),
  ( 'SBand_Transmitter',  ['utility'], ALL_HOSTS, ['TX_'] ),
  ( 'SBand_Transmitter',  ['utility'], ALL_HOSTS, ['TEMP_Klystron'] ),
  ( 'KaTransmitter',  ['server'], ALL_HOSTS, ['KaTransmitter'] ),
  ( 'KaReceiver',  ['server'], ALL_HOSTS, ['KaReceiver','KaBandTestPulse'] ),
  ( 'OpenManage',  ['server'], ALL_HOSTS, ['OpenManage'] ),
  ( 'OpenManage',  ['display'], ALL_HOSTS, ['OpenManage'] )	
]


service_contactgroups = [("spol_cg", ALL_HOSTS, [""])]
host_contactgroups = [("spol_cg", ALL_HOSTS)]

# hosts

extra_host_conf["notification_period"] = [
  ("24X7", ["server"], ALL_HOSTS),
  ("24X7", ["utility"], ALL_HOSTS),
]
extra_host_conf["notification_options"] = [
  ("d,u,r,f,s", ["server"], ALL_HOSTS),
]
extra_host_conf["notification_interval"] = [
  ("1", ["server"], ALL_HOSTS),
]
extra_host_conf["check_interval"] = [
  ("1", ["server"], ALL_HOSTS),
]
extra_host_conf["first_notification_delay"] = [
  ("7", ["server"], ALL_HOSTS),
]
extra_host_conf["notifications_enabled"] = [
  ("0", ["display"], ALL_HOSTS),
  ("1", ["server"], ALL_HOSTS),
  ("1", ["utility"], ALL_HOSTS),
]
extra_host_conf["max_check_attempts"] = [
  ("1", ["server"], ALL_HOSTS),
  ("1", ["utility"], ALL_HOSTS),
]

# services

extra_service_conf["notification_period"] = [
  ("24X7",  ALL_HOSTS, [""]),
]

extra_service_conf["notification_options"] = [
  ("w,u,c,r,f,s", ALL_HOSTS, [""]),
]
extra_service_conf["notifications_enabled"] = [
  ("1", ["server"], ALL_HOSTS, [""]),
  ("0", ["display"], ALL_HOSTS,[""]),
  ("1", ["utility"], ALL_HOSTS,[""]),
]
extra_service_conf["notification_interval"] = [
  ("1", ["server"], ALL_HOSTS, [""]),
  ("1", ["utility"], ALL_HOSTS, [""]),
]
extra_service_conf["first_notification_delay"] = [
  ("7", ["server"], ALL_HOSTS, [""]),
  ("7", ["utility"], ALL_HOSTS, [""]),
]
# flap detection
extra_service_conf["flap_detection_enabled"] = [
  ("1", ["server"], ALL_HOSTS, [""]),
  ("1", ["display"], ALL_HOSTS, [""]),
  ("1", ["utility"], ALL_HOSTS, [""]),
]

extra_host_conf["flap_detection_enabled"] = [
  ("1", ["server"], ALL_HOSTS),
  ("1", ["display"], ALL_HOSTS),
  ("1", ["utility"], ALL_HOSTS),
]

# for testing set max_check_attempts to 1

extra_service_conf["max_check_attempts"] = [
  ("1", ALL_HOSTS, [""]),
]

debug_log="/tmp/check_mk.log"

check_parameters = [
 # (1) USB drives   on spol-dm, spol-dm2 gets levels (80, 95)
 ( (80, 95), [ "spol-dm", "spol-dm2" ], [ "fs_/usb/" ]),
]

