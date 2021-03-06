#!/bin/bash
#
# agent-xen-installer.sh
#
# Author: Oguma

# Define
define="define-agent-xen-installer"
[ -f $define ] && . $define

define_common="../define-common-installer"
[ -f $define_common ] && . $define_common

# Checking OS
[ `chk_os` == "XenServer" ] || { \
  msg "[Failed] Not XenServer";
  cstack_logger "[Failed] The OS does not accord. It is not XenServer." ;
  exit 1;
}

# Start install

cstack_logger "Start install of Cloud Stack agent."

set_idmap

# Prepare Xen hotfix install
[ "$fixdir" == "/root/hotfix" ] && rm -fr $fixdir
mkdir -p $fixdir


# Reading iptables.stable
[ -f iptables.stable ] &&  yes | cp -fp iptables.stable ${sysconfig}/iptables

for cmd in restart save
do
  service iptables $cmd
done

# /**
# Xen setup

setenforce permissive
# Xen is not required settings in the /etc/selinux.


# NFS

## Prepare dir
confirm "Is this what Primary storage? (Primary1? Primary2?)[e.g. (1|2|3|4|none)]"
[ "$bool" == "false" ] || mkdir -p /export/primary$num
confirm "Is this what Secondary storage? (secondary1? secondary2?)[e.g. (1|2|3|4|none)]"
[ "$bool" == "false" ] || mkdir -p /export/secondary$num


echo 'PMAP_ARGS=""' > ${sysconfig}/portmap

echo -e "RQUOTAD_PORT=875
LOCKD_TCPPORT=32803
LOCKD_UDPPORT=32769
MOUNTD_PORT=892
STATD_PORT=662
STATD_OUTGOING_PORT=2020" > ${sysconfig}/nfs

echo "/export  *(rw,async,no_root_squash,no_subtree_check)" > /etc/exports


exportfs -a

for srv in portmap nfs
do
  service $srv restart
  chkconfig --add $srv
  chkconfig $srv on
done

# END OF Xen setup
# **/

# /**
# Update dom0_mem

# tmpfile
cur_mem > old_mem.log

# dom0_mem scale up

if [[ $old_mem -lt 3000000 ]];then
  . $xensource_inv

  case ${PRODUCT_VERSION} in
    "6.2."*)
        sed -i.org 's/dom0_mem=${dom0_mem_before_size},max:${dom0_mem_before_size}/dom0_mem=${dom0_mem_after_size},max:${dom0_mem_after_size}/g' $extlinux_conf
        ;;
    "6.0."*)
        sed -i.org 's/dom0_mem=${dom0_mem_before_size}/dom0_mem=${dom0_mem_after_size}/g' $extlinux_conf
        ;;
    *)
        echo "[Failed] Unknown XenServer version."
        cstack_logger "[Failed] XenServer version. No change dom0_mem."
        exit 10
        ;;
  esac

  sync
  echo staticmax=$staticmax
  staticmax=`xe vm-param-get uuid=$CONTROL_DOMAIN_UUID param-name=memory-static-max`
  xe vm-memory-target-set uuid=$CONTROL_DOMAIN_UUID target=$staticmax
fi

# END OF Update dom0_mem
# **/

# Add yum repo & install
chk_pkg_and_install $pkgs

# Check iptables
iptables -L > before_iptables.check

# /**
# Install HOTFIX

xen_fix_ver=$(xen_fix_ver)

for hotfixs in $xen_fix_ver
do
    cd $fixdir
    wget $hotfixs
done

for i in `ls`
do
    unzip $i
    name_label=(${i%.*})
done

if [ $xen_patch_on == "ON" ];then
  for label in ${name_label[@]}
  do
    # Patch Upload
    xe patch-upload file-name=${label}.xsupdate
    # uuid 
    uuid=$(xe patch-list | grep -w $label -1 | head -1 |awk '{print $5}')
    # 
    xe patch-pool-apply uuid=$uuid
  done
fi

# END OF Install HOTFIX
# **/

# For NFS
shutdown -r now
