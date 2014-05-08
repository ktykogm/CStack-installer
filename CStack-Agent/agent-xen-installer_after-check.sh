#!/bin/bash
#
# agent-xen-installer_after-check.sh
#
# Author: Oguma

# Set define
define="define-agent-xen-installer"
[ -f $define ] && . $define

define_common="../define-common-installer"
[ -f $define_common ] && . $define_common

msg "After check for XenServer-Agent on the CloudStack."

cur_mem=$(cur_mem)
old_mem=$(cat old_mem.log)
export_conf=$(cat /etc/export)


msg "Check dom0_mem"

echo "cd /proc/xen/balloon"
cat /proc/xen/balloon

if [ -f old_mem.log ] ;then
  [ $cur_mem -ge $old_mem ] || { \
    cstack_logger "Failed of dom0_mem";
    msg "[Failed] No change dom0_mem.";
    exit 1;
  }
fi

# Check NFS

msg "Start check to NFS" 

if [ "$export_conf" ];then
  exportfs -a
  [ $? -eq 0 ] || { \
      cstack_logger "Failed command of exportfs.";
      msg "[Failed] exportfs -a";
      exit 1 ;
  }

  service nfs status
  [ $? -eq 0 ] || { \
      cstack_logger "Failed status of nfs.";
      msg "[Failed] nfs status";
      exit 1 ;
  }

  service portmap status
  [ $? -eq 0 ] || { \
      cstack_logger "Failed status of portmap.";
      msg "[Failed] portmap status";
      exit 1 ;
  }
fi

# Check iptables
msg "Start check to iptables"

iptables -L > after_iptables.check

chk_iptables=$(diff after_iptables.check before_iptables.check)


# GREXenPatchŬ & ư
# 
# Caseʸ< ACCEPT gre ʬifʸȽ
# elif

chk_diff_gre=$(echo $chk_iptables | grep gre)


if [ "$chk_diff_gre" = '3d2 < ACCEPT gre -- anywhere anywhere' ]; then
  echo "Added accept gre to iptables. It's ok."
else
  RETVAL=2
fi

if [[ $chk_iptables = "" ]] ;then
  echo "Did not find differences between iptables."
else
  if [[ $RETVAL -eq 2 ]] ;then
    cstack_logger "Failed iptabls. Have been change."
    msg "[Failed] iptables. Have been change."
    exit 1
  fi
fi


# Check NTP

msg "Start check to NTP"
service ntpd status

[ $? -eq 0 ] || { \
  cstack_logger "Failed status of NTP.";
  msg "[Failed] NTP status";
  exit 1 ;
}

msg "Now time is `date`"

ntpq -p
[ $? -eq 0 ] || { \
  cstack_logger "Failed sync of NTP.";
  msg "[Failed] NTP sync";
  exit 1 ;
}

msg "Finished of After check for the XenServer-Agent"

# Clean

echo "Clean after check files.."

for i in old_mem.log after_iptables.check before_iptables.check
do
  rm -f $i
done
