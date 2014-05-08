#!/bin/bash
#
# CloudStack Reinstaller.
#
# clstack-reinstaller.sh
#
# Author: Oguma

# Check define
define=define-manage-installer
[ -f $define ] && . $define

define_common="../define-common-installer"
[ -f $define_common ] && . $define_common

# Checking OS
[ `chk_os` == "XenServer" ] && { \
  msg "[Failed] This is XenServer, It's not CentOS for manager. ";
  cstack_logger "[Failed] The OS does not accord. It is not CentOS." ;
  exit 1;
}

[[ "$1" ]] || { \
  echo "Please passswd.";
  echo ;
  echo "ex) $0 -p <password>" 
  exit 1
} 

# Confirm start.
_confirm "Do you executing a reinstallation of the Cloudstack?"


echo "Prepare Install"
echo
sleep 1

echo "Check of access ssh."
echo
echo
msg "To agents, don't use Password."

echo "[Check] Command of  \$ ssh $agent1"
ssh $agent1 "echo login to $HOSTNAME"
echo "[Check] Command of  \$ ssh $agent2"
ssh $agent2 "echo login to $HOSTNAME"


getopts "p:" OPT
case ${OPT} in
    p) passwd=${OPTARG} ;;
    *) ;;
esac

[ $ipcheck ] || { \
  echo "Manager is not.";
  exit 1 
}


msg "Start install of CloudStack master."

# Prepare NFS
#
# Create mount point
echo "Prepare nfs"
echo
_mk_mntpoint $mnt_secondary

set_idmap


# SELINUX

setenforce permissive

sed "s/SELINUX=.*$/SELINUX=permissive/" /etc/selinux/config

# Start reinstall
for service in mysqld tomcat6 cloudstack-manangement
do
  service $service stop
done

yum erase -y mysql-server tomcat6 cloudstack-manangement

## Removing ##
# Initialize
#
# 物理的にmysqlのfileを全削除
rm -fr /var/lib/mysql

for nfs_dir in primary{,2} secondary{,2}
do
  _action_agent rm -fr /export/${nfs_dir}/* 2> /dev/null
done

## End of Removing ##


yum install -y ntp mysql-server cloudstack-management

service ntpd start


# MySQL
service mysqld start

mysql_secure_installation


# NFS Client

for srv in rpcbind nfs
do
  service $srv restart
  chkconfig --add $srv
  chkconfig $srv on
done

# CloudStack setups
cloudstack-setup-databases cloud:${passwd}@localhost \
--deploy-as=root:${passwd}

cloudstack-setup-management

# Checking systemp url
#
# Handling in the hypervisor type and CloudStack Ver.
_chk_hypervisor


# Install of sys-tmplt for the cloudstack-manager.
for i in $agent{1..2}
do
  case $i in
  "$agent1")
    n=""
    ;;
  "$agent2")
    n="2"
    ;;
 esac
  mount -t nfs ${i}:/export/secondary${n} /mnt/secondary${n}

  echo "Install Sys-template"
  echo
  echo "Now executing on the secondary${n}..."
  echo
  echo
  /usr/share/cloudstack-common/scripts/storage/secondary/cloud-install-sys-tmplt \
  -m /mnt/secondary${n} \
  -u $systemp_url \
  -h xenserver -F

  umount /mnt/secondary${n}
done

# iptables
_action_agent "yes | cp -fp /etc/sysconfig/iptables.stable /etc/sysconfig/iptables; \
  service iptables restart; \
  service iptables save"


echo "Finished reinstall of the CloudStack."
echo
echo
echo "Please access to http://${ipaddress}:8080/client"
